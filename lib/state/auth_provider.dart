import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../models/json.dart';
import '../models/user.dart';

/// Holds the signed-in user, their JWT and saved addresses.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api) {
    _api.onUnauthorized = () => logout(sessionExpired: true);
  }

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  final ApiClient _api;

  AppUser? _user;
  List<Address> _addresses = const [];
  bool _ready = false;
  bool _sessionExpired = false;

  AppUser? get user => _user;
  List<Address> get addresses => _addresses;
  bool get isLoggedIn => _user != null && _api.token != null;
  bool get isReady => _ready;

  /// True once after the server rejected a stored session; reading it clears the flag.
  bool takeSessionExpired() {
    final value = _sessionExpired;
    _sessionExpired = false;
    return value;
  }

  /// Restores a saved session on app start.
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);
      if (token != null && userJson != null) {
        _api.token = token;
        _user = AppUser.fromJson(asMap(jsonDecode(userJson)));
      }
    } catch (_) {
      // Corrupt or unavailable storage: start signed out.
    }
    _ready = true;
    notifyListeners();
    if (isLoggedIn) await loadAddresses();
  }

  Future<void> login(String email, String password) async {
    final data = asMap(await _api.post('/user/login', {'email': email.trim(), 'password': password}));
    final token = data['token']?.toString();
    if (token == null) throw ApiException('Login failed. Please try again.');
    _api.token = token;
    final userJson = asMap(data['user']);
    _user = AppUser.fromJson(userJson);
    _addresses = Address.listFrom(userJson['addresses']);
    await _persist();
    notifyListeners();
  }

  Future<void> signup(String name, String email, String password) async {
    await _api.post('/user/signup', {'name': name.trim(), 'email': email.trim(), 'password': password});
    await login(email, password);
  }

  Future<void> logout({bool sessionExpired = false}) async {
    if (_user == null && _api.token == null) return;
    _api.token = null;
    _user = null;
    _addresses = const [];
    _sessionExpired = sessionExpired;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> updateProfile({required String name, required String phone}) async {
    await _api.put('/user/update', {'name': name.trim(), 'phone': phone.trim()});
    _user = _user?.copyWith(name: name.trim(), phone: phone.trim());
    await _persist();
    notifyListeners();
  }

  Future<void> loadAddresses() async {
    if (!isLoggedIn) return;
    try {
      _addresses = Address.listFrom(await _api.get('/user/orders/address/all'));
      notifyListeners();
    } on ApiException {
      // Keep whatever we had; screens can retry.
    }
  }

  /// Saves a new address and returns it (with its server id).
  Future<Address> addAddress(Address address) async {
    final data = asMap(await _api.post('/user/address/add', address.toJson()));
    _addresses = Address.listFrom(data['addresses']);
    notifyListeners();
    return _addresses.isNotEmpty ? _addresses.last : address;
  }

  Future<void> removeAddress(String id) async {
    final data = asMap(await _api.delete('/user/address/remove/$id'));
    _addresses = Address.listFrom(data['addresses']);
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = _api.token;
      final user = _user;
      if (token != null && user != null) {
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userKey, jsonEncode(user.toJson()));
      }
    } catch (_) {}
  }
}
