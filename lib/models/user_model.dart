// lib/models/user_model.dart

class UserModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role; // 'admin' or 'user'
  final String token;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // DummyJSON returns role as "admin" for emily
    // We also check username as a fallback
    String role = json['role'] ?? 'user';

    // Fallback: if role didn't come through, check username
    const adminUsers = ['emilys', 'admin'];
    if (adminUsers.contains(json['username'])) {
      role = 'admin';
    }

    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      role: role,
      token: json['accessToken'] ?? '',
    );
  }}
