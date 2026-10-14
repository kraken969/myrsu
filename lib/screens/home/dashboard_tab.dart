import 'package:flutter/material.dart';

import '../../models/course_entry.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/course_card.dart';
import '../../widgets/next_class_banner.dart';
import '../course/add_edit_course_screen.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser!.uid;
    final todayIndex = DateTime.now().weekday - 1;

    return StreamBuilder<List<CourseEntry>>(
      stream: FirestoreService.instance.watchTimetable(uid),
      builder: (context, snap) {
        final courses = snap.data ?? [];
        final today = courses.where((c) => c.day == todayIndex).toList()
          ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NextClassBanner(allCourses: courses),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _StatCard(label: 'Total courses', value: '${courses.length}', icon: Icons.menu_book_outlined)),
                  const SizedBox(width: 14),
                  Expanded(child: _StatCard(label: "Today's classes", value: '${today.length}', icon: Icons.today_outlined)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Today's schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddEditCourseScreen())),
                    icon: const Icon(Icons.add),
                    label: const Text('Add course'),
                  ),
                ],
              ),
              if (today.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('No classes today — enjoy the break!', style: Theme.of(context).textTheme.bodyMedium),
                )
              else
                ...today.map((c) => CourseCard(course: c)),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: RsuColors.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: RsuColors.gold),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
