import 'package:flutter/material.dart';

import '../../models/course_entry.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/timetable_grid.dart';
import '../course/add_edit_course_screen.dart';

class TimetableTab extends StatelessWidget {
  const TimetableTab({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser!.uid;

    return StreamBuilder<List<CourseEntry>>(
      stream: FirestoreService.instance.watchTimetable(uid),
      builder: (context, snap) {
        final courses = snap.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Weekly timetable', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddEditCourseScreen())),
                  icon: const Icon(Icons.add),
                  label: const Text('Add course'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: courses.isEmpty
                  ? Center(
                      child: Text('Your timetable is empty.\nTap "Add course" to get started.',
                          textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                    )
                  : Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TimetableGrid(
                          courses: courses,
                          onTapCourse: (course) => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => AddEditCourseScreen(existing: course)),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
