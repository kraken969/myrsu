import 'package:flutter/material.dart';

import '../models/course_entry.dart';
import '../theme/app_theme.dart';

class CourseCard extends StatelessWidget {
  final CourseEntry course;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CourseCard({super.key, required this.course, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tints = isDark ? RsuColors.courseTintsDark : RsuColors.courseTints;
    final tint = tints[course.colorIndex % tints.length];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(width: 8, height: 46, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${course.code} · Sec ${course.section}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                    if (course.title.isNotEmpty)
                      Text(course.title, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text('${course.dayName} · ${course.timeRange} · ${course.room}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  color: RsuColors.danger,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
