class Major {
  final String id;
  final String name;
  final String faculty;

  const Major({required this.id, required this.name, required this.faculty});

  factory Major.fromMap(String id, Map<String, dynamic> map) {
    return Major(
      id: id,
      name: map['name'] ?? '',
      faculty: map['faculty'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'faculty': faculty};
}
