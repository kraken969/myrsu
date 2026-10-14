import 'package:flutter/material.dart';

import '../../models/course_entry.dart';
import '../../models/personal_event.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/course_card.dart';
import '../../widgets/event_card.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  late Future<List<CourseEntry>> _coursesFuture;
  late Future<List<PersonalEvent>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final uid = AuthService.instance.currentUser!.uid;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final dayIndex = tomorrow.weekday - 1;
    _coursesFuture = FirestoreService.instance.fetchCoursesForDay(uid, dayIndex);
    _eventsFuture = FirestoreService.instance
        .fetchEventsForDate(uid, tomorrow)
        .then((events) => events.where((e) => e.remindDayBefore).toList());
  }

  Widget _errorBox(Object? error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: RsuColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: RsuColors.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Could not load this: $error',
                style: const TextStyle(color: RsuColors.danger, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => setState(_load),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final granted = NotificationService.instance.permissionGranted;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!granted)
            Card(
              color: RsuColors.gold.withOpacity(0.12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, color: RsuColors.gold),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Turn on browser notifications to get reminded the evening before your classes and personal reminders.')),
                    TextButton(
                      onPressed: () async {
                        await NotificationService.instance.requestPermission();
                        if (mounted) setState(() {});
                      },
                      child: const Text('Enable'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text('Tomorrow — classes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FutureBuilder<List<CourseEntry>>(
            future: _coursesFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
              }
              if (snap.hasError) {
                return _errorBox(snap.error);
              }
              final classes = snap.data ?? [];
              if (classes.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('No classes scheduled for tomorrow.', style: Theme.of(context).textTheme.bodyMedium),
                );
              }
              return Column(children: classes.map((c) => CourseCard(course: c)).toList());
            },
          ),
          const SizedBox(height: 24),
          const Text('Tomorrow — personal reminders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FutureBuilder<List<PersonalEvent>>(
            future: _eventsFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
              }
              if (snap.hasError) {
                return _errorBox(snap.error);
              }
              final events = snap.data ?? [];
              if (events.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('No personal reminders set for tomorrow.', style: Theme.of(context).textTheme.bodyMedium),
                );
              }
              return Column(children: events.map((e) => EventCard(event: e)).toList());
            },
          ),
        ],
      ),
    );
  }
}