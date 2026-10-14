import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final granted = NotificationService.instance.permissionGranted;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Appearance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('Match system'),
                    value: ThemeMode.system,
                    groupValue: themeProvider.mode,
                    onChanged: (m) => themeProvider.setMode(m!),
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Light'),
                    value: ThemeMode.light,
                    groupValue: themeProvider.mode,
                    onChanged: (m) => themeProvider.setMode(m!),
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Dark'),
                    value: ThemeMode.dark,
                    groupValue: themeProvider.mode,
                    onChanged: (m) => themeProvider.setMode(m!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(granted ? Icons.notifications_active : Icons.notifications_off_outlined,
                    color: granted ? RsuColors.teal : RsuColors.danger),
                title: const Text('Browser notifications'),
                subtitle: Text(granted ? 'Enabled — you\'ll be reminded the day before classes.' : 'Disabled'),
                trailing: granted
                    ? null
                    : TextButton(
                        onPressed: () async {
                          await NotificationService.instance.requestPermission();
                          if (mounted) setState(() {});
                        },
                        child: const Text('Enable'),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline, color: RsuColors.navy),
                title: Text('MyRSU'),
                subtitle: Text('v1.0.0 — Unofficial student companion app for RSU.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
