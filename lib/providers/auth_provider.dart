import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/shift.dart';
import '../database/database_helper.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  Shift? _currentShift;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  User? get currentUser => _currentUser;
  Shift? get currentShift => _currentShift;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isOwner => _currentUser?.isOwner ?? false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _error = null;

    try {
      // Cek apakah sudah ada user di database
      final userCount = await DatabaseHelper.instance.getUserCount();

      // Kalau belum ada user, buat user owner default
      if (userCount == 0) {
        await DatabaseHelper.instance.insertUser(
          User(
            name: 'Owner',
            email: 'owner@kasirku.com',
            password: 'kasirku123',
            role: 'owner',
          ),
        );
      }

      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await DatabaseHelper.instance.getUserByEmailPassword(
        email,
        password,
      );

      if (user == null) {
        _error = 'Email atau password salah';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = user;

      // Start shift
      await DatabaseHelper.instance.startShift(user.id!, user.name);
      final shift = await DatabaseHelper.instance.getActiveShift(user.id!);
      _currentShift = shift;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    if (_currentUser != null) {
      await DatabaseHelper.instance.endShift(_currentUser!.id!);
    }

    _currentUser = null;
    _currentShift = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
