import 'package:flutter/material.dart';

import '../models/course_entry.dart';
import '../theme/app_theme.dart';

/// Renders a Mon-Sun x 7:00-21:00 grid with colored course blocks,
/// visually modeled on the RSU "Study/Exam Timetable" page.
class TimetableGrid extends StatelessWidget {
  final List<CourseEntry> courses;
  final void Function(CourseEntry course)? onTapCourse;

  const TimetableGrid({super.key, required this.courses, this.onTapCourse});

  static const int startHour = 7;
  static const int endHour = 21;
  static const double hourWidth = 96;
  static const double rowHeight = 100;
  static const double dayLabelWidth = 64;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hours = List.generate(endHour - startHour, (i) => startHour + i);
    final gridLine = isDark ? const Color(0xFF26305C) : const Color(0xFFE3E7F2);
    final headerColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return SingleChildScrollView(
      child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: dayLabelWidth + hours.length * hourWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hour header row
            Row(
              children: [
                SizedBox(width: dayLabelWidth),
                ...hours.map(
                  (h) => SizedBox(
                    width: hourWidth,
                    child: Text(
                      '${h.toString().padLeft(2, '0')}:00',
                      style: TextStyle(fontSize: 12, color: headerColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(height: 1, color: gridLine),
            // One row per day
            for (int day = 0; day < 7; day++) _dayRow(context, day, hours, gridLine, isDark),
          ],
        ),
      ),
      ),
    );
  }

  Widget _dayRow(BuildContext context, int day, List<int> hours, Color gridLine, bool isDark) {
    final dayCourses = courses.where((c) => c.day == day).toList();
    return Container(
      height: rowHeight,
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: gridLine))),
      child: Stack(
        children: [
          Row(
            children: [
              SizedBox(
                width: dayLabelWidth,
                child: Center(
                  child: Text(
                    CourseEntry.dayNames[day],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              ...hours.map(
                (_) => Container(
                  width: hourWidth,
                  decoration: BoxDecoration(border: Border(left: BorderSide(color: gridLine))),
                ),
              ),
            ],
          ),
          for (final course in dayCourses) _courseBlock(context, course, isDark),
        ],
      ),
    );
  }

  Widget _courseBlock(BuildContext context, CourseEntry course, bool isDark) {
    final tints = isDark ? RsuColors.courseTintsDark : RsuColors.courseTints;
    final tint = tints[course.colorIndex % tints.length];
    final textColor = isDark ? Colors.white : const Color(0xFF3A3220);

    final startOffsetH = (course.startMinutes / 60) - startHour;
    final durationH = (course.endMinutes - course.startMinutes) / 60;
    final left = dayLabelWidth + startOffsetH * hourWidth;
    final width = durationH * hourWidth;

    return Positioned(
      left: left + 4,
      top: 6,
      width: width - 8,
      height: rowHeight - 12,
      child: GestureDetector(
        onTap: onTapCourse == null ? null : () => onTapCourse!(course),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: textColor.withOpacity(0.35), width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                course.code,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text('Sec : ${course.section}', style: TextStyle(fontSize: 11, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(course.room, style: TextStyle(fontSize: 11, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(course.timeRange, style: TextStyle(fontSize: 10.5, color: textColor.withOpacity(0.85)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}