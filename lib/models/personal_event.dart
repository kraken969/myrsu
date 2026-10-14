import 'package:cloud_firestore/cloud_firestore.dart';

/// A student-created calendar entry — separate from the school
/// timetable (CourseEntry). Unlike courses, which repeat weekly on a
/// day-of-week, a PersonalEvent is tied to one specific calendar
/// [date] (assignment due dates, appointments, personal reminders,
/// etc.) and can optionally trigger the same "remind me the day
/// before" notification used for classes.
class PersonalEvent {
  final String id;
  final String title;
  final String notes;
  final DateTime date; // calendar day only — time of day lives below
  final bool allDay;
  final int? startMinutes; // minutes since midnight, null if allDay
  final int? endMinutes;
  final String location;
  final int colorIndex;
  final bool remindDayBefore;

  PersonalEvent({
    required this.id,
    required this.title,
    required this.date,
    this.notes = '',
    this.allDay = true,
    this.startMinutes,
    this.endMinutes,
    this.location = '',
    this.colorIndex = 0,
    this.remindDayBefore = true,
  });

  factory PersonalEvent.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['date'];
    final rawDate = ts is Timestamp ? ts.toDate() : DateTime.now();
    return PersonalEvent(
      id: id,
      title: map['title'] ?? '',
      notes: map['notes'] ?? '',
      date: DateTime(rawDate.year, rawDate.month, rawDate.day),
      allDay: map['allDay'] ?? true,
      startMinutes: map['startMinutes'],
      endMinutes: map['endMinutes'],
      location: map['location'] ?? '',
      colorIndex: map['colorIndex'] ?? 0,
      remindDayBefore: map['remindDayBefore'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'notes': notes,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'allDay': allDay,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'location': location,
      'colorIndex': colorIndex,
      'remindDayBefore': remindDayBefore,
    };
  }

  String get timeLabel {
    if (allDay || startMinutes == null) return 'All day';
    String fmt(int m) {
      final h = (m ~/ 60).toString().padLeft(2, '0');
      final mm = (m % 60).toString().padLeft(2, '0');
      return '$h:$mm';
    }

    if (endMinutes == null) return fmt(startMinutes!);
    return '${fmt(startMinutes!)} - ${fmt(endMinutes!)}';
  }

  bool isSameDay(DateTime other) => date.year == other.year && date.month == other.month && date.day == other.day;
}
