class UserModel {
  const UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  final String userId;
  final String name;
  final String email;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'name': name,
    'email': email,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
