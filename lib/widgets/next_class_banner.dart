import 'package:flutter/material.dart';

import '../models/course_entry.dart';
import '../theme/app_theme.dart';

/// Finds and displays the next upcoming class from [allCourses],
/// looking across the rest of today first, then forward day by day.
/// A nice "what's next" convenience so students don't have to scan
/// the whole grid every time they open the app.
class NextClassBanner extends StatelessWidget {
  final List<CourseEntry> allCourses;

  const NextClassBanner({super.key, required this.allCourses});

  @override
  Widget build(BuildContext context) {
    final next = _findNext(allCourses);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (next == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? RsuColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            Icon(Icons.beach_access, color: RsuColors.gold),
            SizedBox(width: 12),
            Expanded(child: Text('No upcoming classes on your timetable yet — add your courses to get started.')),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [RsuColors.navy, RsuColors.navyLight]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.schedule, color: RsuColors.gold, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Next class', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${next.code} · Sec ${next.section}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('${next.dayName} · ${next.timeRange} · ${next.room}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  CourseEntry? _findNext(List<CourseEntry> courses) {
    if (courses.isEmpty) return null;
    final now = DateTime.now();
    final todayIndex = now.weekday - 1; // 0=Mon..6=Sun
    final nowMinutes = now.hour * 60 + now.minute;

    for (int offset = 0; offset < 7; offset++) {
      final dayIndex = (todayIndex + offset) % 7;
      final dayCourses = courses.where((c) => c.day == dayIndex).toList()
        ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

      for (final c in dayCourses) {
        if (offset > 0 || c.startMinutes > nowMinutes) {
          return c;
        }
      }
    }
    return null;
  }
}
