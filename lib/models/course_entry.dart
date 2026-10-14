/// A single course/section block on the student's weekly timetable.
///
/// [day] is 0=Mon … 6=Sun (matches the RSU portal's Mon-first layout).
/// [startMinutes]/[endMinutes] are minutes since midnight, e.g. 9:00 = 540.
class CourseEntry {
  final String id;
  final String code; // e.g. CSC480
  final String title; // e.g. Software Project Management
  final String section; // e.g. 142
  final String room; // e.g. 6-404 A
  final String instructor;
  final int day;
  final int startMinutes;
  final int endMinutes;
  final int colorIndex; // picks a tint from RsuColors.courseTints

  CourseEntry({
    required this.id,
    required this.code,
    required this.title,
    required this.section,
    required this.room,
    required this.day,
    required this.startMinutes,
    required this.endMinutes,
    this.instructor = '',
    this.colorIndex = 0,
  });

  factory CourseEntry.fromMap(String id, Map<String, dynamic> map) {
    return CourseEntry(
      id: id,
      code: map['code'] ?? '',
      title: map['title'] ?? '',
      section: map['section'] ?? '',
      room: map['room'] ?? '',
      instructor: map['instructor'] ?? '',
      day: map['day'] ?? 0,
      startMinutes: map['startMinutes'] ?? 540,
      endMinutes: map['endMinutes'] ?? 600,
      colorIndex: map['colorIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'title': title,
      'section': section,
      'room': room,
      'instructor': instructor,
      'day': day,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'colorIndex': colorIndex,
    };
  }

  String get timeRange {
    String fmt(int m) {
      final h = (m ~/ 60).toString().padLeft(2, '0');
      final mm = (m % 60).toString().padLeft(2, '0');
      return '$h:$mm';
    }

    return '${fmt(startMinutes)} - ${fmt(endMinutes)}';
  }

  static const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  String get dayName => dayNames[day];
}
