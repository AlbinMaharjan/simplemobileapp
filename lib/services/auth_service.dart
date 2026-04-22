// lib/services/auth_service.dart
//
// Uses DummyJSON free REST API: https://dummyjson.com/docs/auth
//
// Test credentials from DummyJSON:
//   Admin : username="emilys"    password="emilyspass"   (role=admin)
//   User  : username="michaelw"  password="michaelwpass" (role=moderator → treated as user)
//
// Any valid DummyJSON user works. Role comes back in the login response.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _baseUrl = 'https://dummyjson.com';
  static const String _userKey = 'logged_user';

  // ---------- LOGIN ----------
  Future<UserModel> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data);

      // Persist user locally so app remembers login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(data));

      return user;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Login failed');
    }
  }

  // ---------- GET CACHED USER ----------
  Future<UserModel?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw));
  }

  // ---------- LOGOUT ----------
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
