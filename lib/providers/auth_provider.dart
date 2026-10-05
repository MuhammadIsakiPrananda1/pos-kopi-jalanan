import 'package:flutter/material.dart';

enum UserRole {
  admin,
  karyawan,
}

class AppUser {
  final String id;
  final String username;
  final String name;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isKaryawan => role == UserRole.karyawan;
}

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isKaryawan => _currentUser?.isKaryawan ?? false;

  // Preset Users
  static const AppUser adminUser = AppUser(
    id: 'user_admin',
    username: 'admin',
    name: 'Admin Utama',
    role: UserRole.admin,
  );

  static const AppUser karyawanUser = AppUser(
    id: 'user_karyawan',
    username: 'karyawan',
    name: 'Staff Kasir',
    role: UserRole.karyawan,
  );

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 400));

    final cleanUsername = username.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanUsername == 'admin' && (cleanPassword == 'admin123' || cleanPassword == 'admin')) {
      _currentUser = adminUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } else if ((cleanUsername == 'karyawan' || cleanUsername == 'kasir') &&
        (cleanPassword == '1234' || cleanPassword == 'karyawan' || cleanPassword == 'kasir')) {
      _currentUser = karyawanUser;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void loginAs(UserRole role) {
    if (role == UserRole.admin) {
      _currentUser = adminUser;
    } else {
      _currentUser = karyawanUser;
    }
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
