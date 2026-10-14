class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? studentId;
  final String? majorId;
  final String? majorName;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.studentId,
    this.majorId,
    this.majorName,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      studentId: map['studentId'],
      majorId: map['majorId'],
      majorName: map['majorName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'studentId': studentId,
      'majorId': majorId,
      'majorName': majorName,
    };
  }

  AppUser copyWith({
    String? name,
    String? photoUrl,
    String? studentId,
    String? majorId,
    String? majorName,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      studentId: studentId ?? this.studentId,
      majorId: majorId ?? this.majorId,
      majorName: majorName ?? this.majorName,
    );
  }

  /// True once the student has picked a major — used to decide whether
  /// to route into onboarding right after sign-in.
  bool get hasCompletedOnboarding => majorId != null && majorId!.isNotEmpty;
}
