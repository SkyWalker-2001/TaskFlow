import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import 'mongo_service.dart';

class AuthService {
  AuthService({MongoService? mongoService})
    : _mongoService = mongoService ?? MongoService();

  static const sessionUserIdKey = 'auth.userId';
  static const sessionNameKey = 'auth.name';
  static const sessionEmailKey = 'auth.email';
  static const _localUsersKey = 'auth.localUsers';

  final MongoService _mongoService;
  String? _lastError;

  String? get lastError => _lastError;

  Future<UserModel?> getCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(sessionUserIdKey);
    final name = prefs.getString(sessionNameKey);
    final email = prefs.getString(sessionEmailKey);

    if (userId == null || name == null || email == null) {
      return null;
    }

    return UserModel(
      userId: userId,
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    _lastError = null;

    final normalizedEmail = email.trim().toLowerCase();
    final userDoc = await _mongoService.findUserByEmail(normalizedEmail);
    if (userDoc != null) {
      final storedHash = userDoc['password']?.toString() ?? '';
      final incomingHash = _hashPassword(normalizedEmail, password);
      if (storedHash != incomingHash) {
        _lastError = 'Invalid email or password';
        return null;
      }

      final user = UserModel(
        userId: userDoc['_id'].toString(),
        name: userDoc['name']?.toString() ?? 'User',
        email: userDoc['email']?.toString() ?? normalizedEmail,
        createdAt:
            DateTime.tryParse(userDoc['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );

      await _saveSession(user);
      return user;
    }

    final localUser = await _findLocalUserByEmail(normalizedEmail);
    if (localUser == null) {
      _lastError = _mongoService.lastError ?? 'Invalid email or password';
      return null;
    }
    final localStoredHash = localUser['password']?.toString() ?? '';
    final localIncomingHash = _hashPassword(normalizedEmail, password);
    if (localStoredHash != localIncomingHash) {
      _lastError = 'Invalid email or password';
      return null;
    }

    final user = UserModel(
      userId: localUser['userId']?.toString() ?? '',
      name: localUser['name']?.toString() ?? 'User',
      email: localUser['email']?.toString() ?? normalizedEmail,
      createdAt:
          DateTime.tryParse(localUser['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );

    await _saveSession(user);
    return user;
  }

  Future<UserModel?> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    _lastError = null;

    final normalizedEmail = email.trim().toLowerCase();
    final existingRemote = await _mongoService.findUserByEmail(normalizedEmail);
    final existingLocal = await _findLocalUserByEmail(normalizedEmail);
    if (existingRemote != null || existingLocal != null) {
      _lastError = 'Email already exists';
      return null;
    }

    final userId = DateTime.now().microsecondsSinceEpoch.toString();
    final createdRemote = await _mongoService.createUser(
      userId: userId,
      name: name.trim(),
      email: normalizedEmail,
      passwordHash: _hashPassword(normalizedEmail, password),
    );

    if (!createdRemote) {
      final createdLocal = await _createLocalUser(
        userId: userId,
        name: name.trim(),
        email: normalizedEmail,
        passwordHash: _hashPassword(normalizedEmail, password),
      );
      if (!createdLocal) {
        _lastError = _mongoService.lastError ?? 'Unable to sign up';
        return null;
      }
    }

    final user = UserModel(
      userId: userId,
      name: name.trim(),
      email: normalizedEmail,
      createdAt: DateTime.now(),
    );

    await _saveSession(user);
    return user;
  }

  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    _lastError = null;

    final normalizedEmail = email.trim().toLowerCase();
    final existingRemote = await _mongoService.findUserByEmail(normalizedEmail);
    final existingLocal = await _findLocalUserByEmail(normalizedEmail);
    if (existingRemote == null && existingLocal == null) {
      _lastError = 'Email not found';
      return false;
    }

    final updatedRemote = await _mongoService.updateUserPassword(
      email: normalizedEmail,
      passwordHash: _hashPassword(normalizedEmail, newPassword),
    );

    if (!updatedRemote) {
      final updatedLocal = await _updateLocalPassword(
        email: normalizedEmail,
        passwordHash: _hashPassword(normalizedEmail, newPassword),
      );
      if (!updatedLocal) {
        _lastError = _mongoService.lastError ?? 'Failed to reset password';
        return false;
      }
    }

    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(sessionUserIdKey);
    await prefs.remove(sessionNameKey);
    await prefs.remove(sessionEmailKey);
  }

  String _hashPassword(String email, String password) {
    final salted = '$email::taskflow::${password.trim()}';
    return sha256.convert(utf8.encode(salted)).toString();
  }

  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(sessionUserIdKey, user.userId);
    await prefs.setString(sessionNameKey, user.name);
    await prefs.setString(sessionEmailKey, user.email);
  }

  Future<Map<String, dynamic>?> _findLocalUserByEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localUsersKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final parsed = jsonDecode(raw);
    if (parsed is! List) {
      return null;
    }

    for (final item in parsed) {
      if (item is Map<String, dynamic>) {
        final current = (item['email']?.toString() ?? '').trim().toLowerCase();
        if (current == email) {
          return item;
        }
      } else if (item is Map) {
        final mapped = Map<String, dynamic>.from(item);
        final current = (mapped['email']?.toString() ?? '')
            .trim()
            .toLowerCase();
        if (current == email) {
          return mapped;
        }
      }
    }
    return null;
  }

  Future<bool> _createLocalUser({
    required String userId,
    required String name,
    required String email,
    required String passwordHash,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localUsersKey);
    final parsed = raw == null || raw.isEmpty ? <dynamic>[] : jsonDecode(raw);
    final list = parsed is List ? List<dynamic>.from(parsed) : <dynamic>[];

    final exists = list.any((item) {
      if (item is Map) {
        final mapped = Map<String, dynamic>.from(item);
        return (mapped['email']?.toString() ?? '').trim().toLowerCase() ==
            email;
      }
      return false;
    });
    if (exists) {
      return false;
    }

    list.add({
      'userId': userId,
      'name': name,
      'email': email,
      'password': passwordHash,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_localUsersKey, jsonEncode(list));
    return true;
  }

  Future<bool> _updateLocalPassword({
    required String email,
    required String passwordHash,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localUsersKey);
    if (raw == null || raw.isEmpty) {
      return false;
    }

    final parsed = jsonDecode(raw);
    if (parsed is! List) {
      return false;
    }

    bool updated = false;
    final list = parsed.map((item) {
      if (item is Map) {
        final mapped = Map<String, dynamic>.from(item);
        final current = (mapped['email']?.toString() ?? '')
            .trim()
            .toLowerCase();
        if (current == email) {
          mapped['password'] = passwordHash;
          updated = true;
        }
        return mapped;
      }
      return item;
    }).toList();

    if (!updated) {
      return false;
    }
    await prefs.setString(_localUsersKey, jsonEncode(list));
    return true;
  }
}
