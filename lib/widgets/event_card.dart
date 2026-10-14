import 'package:flutter/material.dart';

import '../models/personal_event.dart';
import '../theme/app_theme.dart';

class EventCard extends StatelessWidget {
  final PersonalEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const EventCard({super.key, required this.event, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tints = isDark ? RsuColors.courseTintsDark : RsuColors.courseTints;
    final tint = tints[event.colorIndex % tints.length];

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
                    Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                    if (event.notes.isNotEmpty)
                      Text(event.notes, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      [event.timeLabel, if (event.location.isNotEmpty) event.location].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (event.remindDayBefore)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.notifications_active_outlined, size: 18, color: RsuColors.gold),
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
