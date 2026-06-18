class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String phoneNumber;
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.phoneNumber,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      fcmToken: map['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'fcmToken': fcmToken,
    };
  }
}
