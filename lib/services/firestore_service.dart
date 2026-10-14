import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import '../models/course_entry.dart';
import '../models/major.dart';
import '../models/personal_event.dart';
import '../data/sample_majors.dart';

/// All Firestore reads/writes for the app go through here, so the UI
/// layer never touches `cloud_firestore` directly.
///
/// Firestore layout:
///   users/{uid}                              -> profile + chosen major
///   majors/{majorId}                         -> catalog of majors
///   users/{uid}/timetable/{entryId}          -> that student's course blocks
///   users/{uid}/personal_events/{eventId}    -> that student's own calendar entries
class FirestoreService {
  FirestoreService._internal();
  static final FirestoreService instance = FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ---------------- User profile ----------------

  Stream<AppUser?> watchUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromMap(uid, snap.data()!);
    });
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> fields) {
    return _db.collection('users').doc(uid).set(fields, SetOptions(merge: true));
  }

  Future<void> setMajor(String uid, Major major) {
    return updateProfile(uid, {'majorId': major.id, 'majorName': major.name});
  }

  // ---------------- Majors ----------------

  /// Streams the `majors` collection; if it's empty (fresh Firebase
  /// project), seeds it once from [sampleMajors] and falls back to the
  /// local list immediately so the picker is never empty.
  Stream<List<Major>> watchMajors() async* {
    final existing = await _db.collection('majors').limit(1).get();
    if (existing.docs.isEmpty) {
      await _seedMajors();
    }
    yield* _db.collection('majors').orderBy('name').snapshots().map(
          (snap) => snap.docs.map((d) => Major.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> _seedMajors() async {
    final batch = _db.batch();
    for (final m in sampleMajors) {
      batch.set(_db.collection('majors').doc(m.id), m.toMap());
    }
    await batch.commit();
  }

  // ---------------- Timetable ----------------

  CollectionReference<Map<String, dynamic>> _timetableRef(String uid) =>
      _db.collection('users').doc(uid).collection('timetable');

  Stream<List<CourseEntry>> watchTimetable(String uid) {
    return _timetableRef(uid).orderBy('startMinutes').snapshots().map(
          (snap) => snap.docs.map((d) => CourseEntry.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> addCourse(String uid, CourseEntry entry) {
    final id = entry.id.isEmpty ? _uuid.v4() : entry.id;
    return _timetableRef(uid).doc(id).set(entry.toMap());
  }

  Future<void> updateCourse(String uid, CourseEntry entry) {
    return _timetableRef(uid).doc(entry.id).update(entry.toMap());
  }

  Future<void> deleteCourse(String uid, String entryId) {
    return _timetableRef(uid).doc(entryId).delete();
  }

  /// One-off fetch (not a stream) used by [NotificationService] to check
  /// tomorrow's classes without keeping a listener open.
  Future<List<CourseEntry>> fetchCoursesForDay(String uid, int day) async {
    final snap = await _timetableRef(uid).where('day', isEqualTo: day).get();
    return snap.docs.map((d) => CourseEntry.fromMap(d.id, d.data())).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
  }

  // ---------------- Personal calendar ----------------

  CollectionReference<Map<String, dynamic>> _eventsRef(String uid) =>
      _db.collection('users').doc(uid).collection('personal_events');

  /// Streams every personal event (not just one month) — the Calendar
  /// tab needs the full list client-side to show marker dots across
  /// whichever month the student is currently viewing, the same
  /// "fetch once, filter locally" approach used for majors.
  Stream<List<PersonalEvent>> watchPersonalEvents(String uid) {
    return _eventsRef(uid).orderBy('date').snapshots().map(
          (snap) => snap.docs.map((d) => PersonalEvent.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> addPersonalEvent(String uid, PersonalEvent event) {
    final id = event.id.isEmpty ? _uuid.v4() : event.id;
    return _eventsRef(uid).doc(id).set(event.toMap());
  }

  Future<void> updatePersonalEvent(String uid, PersonalEvent event) {
    return _eventsRef(uid).doc(event.id).update(event.toMap());
  }

  Future<void> deletePersonalEvent(String uid, String eventId) {
    return _eventsRef(uid).doc(eventId).delete();
  }

  /// One-off fetch used by [NotificationService] to check tomorrow's
  /// personal events without keeping a listener open.
  Future<List<PersonalEvent>> fetchEventsForDate(String uid, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _eventsRef(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();
    return snap.docs.map((d) => PersonalEvent.fromMap(d.id, d.data())).toList()
      ..sort((a, b) => (a.startMinutes ?? -1).compareTo(b.startMinutes ?? -1));
  }
}
