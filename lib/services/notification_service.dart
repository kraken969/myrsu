// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/course_entry.dart';
import '../models/personal_event.dart';
import 'firestore_service.dart';

/// Combined result of checking tomorrow: school classes plus any
/// personal calendar events the student asked to be reminded about.
class TomorrowSummary {
  final List<CourseEntry> courses;
  final List<PersonalEvent> events;

  TomorrowSummary({required this.courses, required this.events});

  int get totalCount => courses.length + events.length;
  bool get isEmpty => courses.isEmpty && events.isEmpty;
}

/// Reminds the student about classes AND personal calendar events
/// happening *tomorrow*.
///
/// This app is Flutter Web, so reminders use the browser's native
/// Notification API (`dart:html`) — they fire whenever MyRSU is open in
/// a tab. A `shared_preferences` flag makes sure we only notify once per
/// calendar day, even if the user reloads the page repeatedly.
///
/// For reminders that still arrive when the browser/tab is *closed*,
/// wire up Firebase Cloud Messaging + the scheduled Cloud Function in
/// `functions/index.js` (see README "Push notifications" section).
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  static const _lastCheckKey = 'myrsu_last_notify_date';

  Future<bool> requestPermission() async {
    if (!html.Notification.supported) return false;
    final permission = await html.Notification.requestPermission();
    return permission == 'granted';
  }

  bool get permissionGranted =>
      html.Notification.supported && html.Notification.permission == 'granted';

  /// Call once after login / on app resume. Fetches tomorrow's classes
  /// and reminder-flagged personal events for [uid], and shows one
  /// summary browser notification covering both if there's anything
  /// and we haven't already notified today.
  Future<TomorrowSummary> checkTomorrowAndNotify(String uid) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowDayIndex = tomorrow.weekday - 1; // Dart: Mon=1..Sun=7 -> 0=Mon..6=Sun

    final classes = await FirestoreService.instance.fetchCoursesForDay(uid, tomorrowDayIndex);
    final allEvents = await FirestoreService.instance.fetchEventsForDate(uid, tomorrow);
    final events = allEvents.where((e) => e.remindDayBefore).toList();

    final summary = TomorrowSummary(courses: classes, events: events);
    if (summary.isEmpty) return summary;

    final prefs = await SharedPreferences.getInstance();
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    final lastNotified = prefs.getString(_lastCheckKey);

    if (lastNotified != todayKey && permissionGranted) {
      html.Notification(
        'Tomorrow: ${summary.totalCount} ${summary.totalCount == 1 ? "thing" : "things"} on your plate 📚',
        body: _buildBody(classes, events),
      );
      await prefs.setString(_lastCheckKey, todayKey);
    }

    return summary;
  }

  String _buildBody(List<CourseEntry> classes, List<PersonalEvent> events) {
    final parts = <String>[];
    if (classes.isNotEmpty) {
      final first = classes.first;
      parts.add(
        classes.length == 1
            ? '${first.code} Sec ${first.section} at ${first.timeRange}'
            : '${classes.length} classes, starting with ${first.code} at ${first.timeRange}',
      );
    }
    if (events.isNotEmpty) {
      final first = events.first;
      parts.add(
        events.length == 1
            ? first.title
            : '${events.length} personal reminders, starting with "${first.title}"',
      );
    }
    return parts.join(' · ');
  }
}
