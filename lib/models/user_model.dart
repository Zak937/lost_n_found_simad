class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String phoneNumber;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.phoneNumber,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
    };
  }
}
