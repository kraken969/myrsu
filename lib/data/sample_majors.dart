import '../models/major.dart';

/// Used to seed Firestore the first time the app runs, and as an
/// offline fallback list for the major-picker if Firestore has no
/// `majors` collection yet. Feel free to replace with the real RSU
/// program list.
const List<Major> sampleMajors = [
  Major(id: 'cs', name: 'Computer Science', faculty: 'College of Digital Innovation Technology'),
  Major(id: 'se', name: 'Software Engineering', faculty: 'College of Digital Innovation Technology'),
  Major(id: 'it', name: 'Information Technology', faculty: 'College of Digital Innovation Technology'),
  Major(id: 'ba', name: 'Business Administration', faculty: 'College of Business Administration'),
  Major(id: 'acc', name: 'Accounting', faculty: 'College of Business Administration'),
  Major(id: 'arch', name: 'Architecture', faculty: 'Faculty of Architecture'),
  Major(id: 'eng', name: 'Civil Engineering', faculty: 'College of Engineering'),
  Major(id: 'nurse', name: 'Nursing Science', faculty: 'College of Nursing'),
  Major(id: 'comm', name: 'Communication Arts', faculty: 'College of Communication Arts'),
  Major(id: 'law', name: 'Law', faculty: 'Faculty of Law'),
];
