// User Model
class UserModel {
  final String id;
  final String email;
  final String role;
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] ?? '',
        email: j['email'] ?? '',
        role: j['role'] ?? 'Employee',
        isActive: j['isActive'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role,
        'isActive': isActive,
      };
}
