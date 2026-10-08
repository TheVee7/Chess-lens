import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gemini_service.dart';

/// Manages the Gemini API key in on-device encrypted secure storage
/// (via flutter_secure_storage) and handles validation.
class ApiKeyManager extends ChangeNotifier {
  static const _keyPref = 'gemini_api_key';
  final FlutterSecureStorage _secureStorage;

  ApiKeyManager({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  String? _apiKey;
  String? get apiKey => _apiKey;
  bool get hasKey => _apiKey != null && _apiKey!.isNotEmpty;

  bool? _isValid;
  bool? get isValid => _isValid;

  String? _validationError;
  String? get validationError => _validationError;

  bool _isValidating = false;
  bool get isValidating => _isValidating;

  /// Masked display value (never exposes more than the last 4 characters).
  String get maskedKey {
    if (!hasKey) return '';
    final k = _apiKey!;
    if (k.length <= 4) return '••••';
    return '••••••••••${k.substring(k.length - 4)}';
  }

  /// Load saved key from encrypted secure storage.
  /// Automatically migrates any legacy key found in unencrypted SharedPreferences.
  Future<void> load() async {
    String? storedKey = await _secureStorage.read(key: _keyPref);

    // Migration from legacy SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyKey = prefs.getString(_keyPref);
      if (legacyKey != null && legacyKey.isNotEmpty) {
        if (storedKey == null || storedKey.isEmpty) {
          storedKey = legacyKey;
          await _secureStorage.write(key: _keyPref, value: legacyKey);
        }
        await prefs.remove(_keyPref);
      }
    } catch (_) {
      // Ignore migration errors
    }

    _apiKey = storedKey;
    notifyListeners();
  }

  /// Save the key into secure storage and optionally validate it.
  Future<bool> save(String key, {bool validate = true}) async {
    _apiKey = key.trim();
    _isValid = null;
    _validationError = null;
    await _secureStorage.write(key: _keyPref, value: _apiKey!);
    notifyListeners();

    if (validate && hasKey) {
      return await validateKey();
    }
    return true;
  }

  /// Test connectivity and validity of current (or provided) key.
  Future<bool> validateKey([String? customKey]) async {
    final keyToTest = (customKey ?? _apiKey)?.trim();
    if (keyToTest == null || keyToTest.isEmpty) {
      _isValid = false;
      _validationError = 'API key cannot be empty.';
      notifyListeners();
      return false;
    }

    _isValidating = true;
    _validationError = null;
    notifyListeners();

    try {
      final gemini = GeminiService(apiKey: keyToTest);
      final result = await gemini.testKeyResult();
      switch (result) {
        case Success<bool>():
          _isValid = true;
          _validationError = null;
          _isValidating = false;
          notifyListeners();
          return true;
        case Failure<bool>(:final error):
          _isValid = false;
          _validationError = error.description;
          _isValidating = false;
          notifyListeners();
          return false;
      }
    } catch (e) {
      _isValid = false;
      _validationError = 'Connection error: $e';
      _isValidating = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete the key from secure storage and legacy preferences.
  Future<void> delete() async {
    _apiKey = null;
    _isValid = null;
    _validationError = null;
    await _secureStorage.delete(key: _keyPref);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPref);
    } catch (_) {}
    notifyListeners();
  }
}
