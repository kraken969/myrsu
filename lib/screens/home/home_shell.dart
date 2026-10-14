import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../services/account_history_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import 'calendar_tab.dart';
import 'dashboard_tab.dart';
import 'notifications_tab.dart';
import 'profile_tab.dart';
import 'settings_tab.dart';
import 'timetable_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  int _tomorrowCount = 0;
  List<AccountHistoryEntry> _recentAccounts = [];

  static const _titles = ['Dashboard', 'Timetable', 'Calendar', 'Notifications', 'Profile', 'Settings'];
  static const _icons = [
    Icons.dashboard_outlined,
    Icons.calendar_view_week_outlined,
    Icons.calendar_month_outlined,
    Icons.notifications_outlined,
    Icons.person_outline,
    Icons.settings_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadAccountHistory();
  }

  Future<void> _initNotifications() async {
    final granted = await NotificationService.instance.requestPermission();
    if (!granted) return;
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;
    final summary = await NotificationService.instance.checkTomorrowAndNotify(uid);
    if (mounted) setState(() => _tomorrowCount = summary.totalCount);
  }

  Future<void> _loadAccountHistory() async {
    final accounts = await AccountHistoryService.instance.getRecentAccounts();
    if (mounted) setState(() => _recentAccounts = accounts);
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser!.uid;

    return StreamBuilder<AppUser?>(
      stream: FirestoreService.instance.watchUser(uid),
      builder: (context, userSnap) {
        final user = userSnap.data;
        final wide = MediaQuery.of(context).size.width >= 900;

        final pages = [
          const DashboardTab(),
          const TimetableTab(),
          const CalendarTab(),
          const NotificationsTab(),
          const ProfileTab(),
          const SettingsTab(),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(Icons.school, color: RsuColors.gold),
                const SizedBox(width: 10),
                Text(_titles[_index]),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Toggle dark mode',
                icon: Icon(Theme.of(context).brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => context.read<ThemeProvider>().toggle(),
              ),
              Stack(
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () => setState(() => _index = 3),
                  ),
                  if (_tomorrowCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: RsuColors.danger, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text('$_tomorrowCount', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              _ProfileMenu(
                user: user,
                recentAccounts: _recentAccounts,
                onViewProfile: () => setState(() => _index = 4),
              ),
              const SizedBox(width: 16),
            ],
          ),
          drawer: wide ? null : _MobileDrawer(index: _index, onSelect: (i) => setState(() => _index = i), user: user),
          body: Row(
            children: [
              if (wide)
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  destinations: [
                    for (int i = 0; i < _titles.length; i++)
                      NavigationRailDestination(icon: Icon(_icons[i]), label: Text(_titles[i])),
                  ],
                ),
              if (wide) const VerticalDivider(width: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: IndexedStack(index: _index, children: pages),
                ),
              ),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    for (int i = 0; i < _titles.length; i++)
                      NavigationDestination(icon: Icon(_icons[i]), label: _titles[i]),
                  ],
                ),
        );
      },
    );
  }
}

/// The avatar button in the top app bar. Tapping it opens a dropdown
/// with the current account, a "View profile" shortcut, any other
/// accounts remembered on this device ("Account suggestions" — see
/// AccountHistoryService for why this is device-local rather than a
/// real Google account picker), "Add another account", and "Sign out".
class _ProfileMenu extends StatelessWidget {
  final AppUser? user;
  final List<AccountHistoryEntry> recentAccounts;
  final VoidCallback onViewProfile;

  const _ProfileMenu({required this.user, required this.recentAccounts, required this.onViewProfile});

  String _initial(String? name) => (name != null && name.isNotEmpty) ? name[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    final others = recentAccounts.where((a) => a.email != user?.email).toList();

    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 48),
      position: PopupMenuPosition.under,
      itemBuilder: (context) {
        return [
          // Current account header (non-interactive).
          PopupMenuItem<String>(
            enabled: false,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: RsuColors.gold,
                  backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                  child: user?.photoUrl == null
                      ? Text(_initial(user?.name), style: const TextStyle(color: RsuColors.navy, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text(user?.email ?? '', style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'profile',
            child: Row(children: [Icon(Icons.person_outline, size: 20), SizedBox(width: 12), Text('View profile')]),
          ),
          const PopupMenuDivider(),
          if (others.isNotEmpty) ...[
            PopupMenuItem<String>(
              enabled: false,
              height: 28,
              child: Text(
                'ACCOUNT SUGGESTIONS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              ),
            ),
            for (final a in others)
              PopupMenuItem<String>(
                value: 'switch:${a.email}',
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: RsuColors.navy.withOpacity(0.15),
                      backgroundImage: a.photoUrl != null ? NetworkImage(a.photoUrl!) : null,
                      child: a.photoUrl == null ? Text(_initial(a.name), style: const TextStyle(fontSize: 12)) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                          Text(a.email, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const PopupMenuDivider(),
          ],
          const PopupMenuItem<String>(
            value: 'add_account',
            child: Row(children: [Icon(Icons.add, size: 20), SizedBox(width: 12), Text('Add another account')]),
          ),
          const PopupMenuItem<String>(
            value: 'signout',
            child: Row(children: [
              Icon(Icons.logout, size: 20, color: RsuColors.danger),
              SizedBox(width: 12),
              Text('Sign out', style: TextStyle(color: RsuColors.danger)),
            ]),
          ),
        ];
      },
      onSelected: (value) {
        if (value == 'profile') {
          onViewProfile();
        } else if (value == 'add_account') {
          AuthService.instance.switchAccount(null);
        } else if (value == 'signout') {
          AuthService.instance.signOut();
        } else if (value.startsWith('switch:')) {
          AuthService.instance.switchAccount(value.substring('switch:'.length));
        }
      },
      child: CircleAvatar(
        radius: 16,
        backgroundColor: RsuColors.gold,
        backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
        child: user?.photoUrl == null
            ? Text(_initial(user?.name), style: const TextStyle(color: RsuColors.navy, fontWeight: FontWeight.bold))
            : null,
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  final AppUser? user;

  const _MobileDrawer({required this.index, required this.onSelect, required this.user});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(radius: 24, backgroundColor: RsuColors.navy, child: Icon(Icons.school, color: RsuColors.gold)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(user?.majorName ?? '', style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            for (int i = 0; i < _HomeShellState._titles.length; i++)
              ListTile(
                leading: Icon(_HomeShellState._icons[i]),
                title: Text(_HomeShellState._titles[i]),
                selected: index == i,
                selectedTileColor: RsuColors.navy.withOpacity(0.08),
                onTap: () {
                  Navigator.pop(context);
                  onSelect(i);
                },
              ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: RsuColors.danger),
              title: const Text('Log out', style: TextStyle(color: RsuColors.danger)),
              onTap: () => AuthService.instance.signOut(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
