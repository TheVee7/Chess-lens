import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gemini_service.dart';

/// Manages the Gemini API key in secure local storage and handles verification.
class ApiKeyManager extends ChangeNotifier {
  static const _keyPref = 'gemini_api_key';

  String? _apiKey;
  String? get apiKey => _apiKey;
  bool get hasKey => _apiKey != null && _apiKey!.isNotEmpty;

  bool? _isValid;
  bool? get isValid => _isValid;

  String? _validationError;
  String? get validationError => _validationError;

  bool _isValidating = false;
  bool get isValidating => _isValidating;

  /// Masked display value (e.g. "••••••••••a3Bc").
  String get maskedKey {
    if (!hasKey) return '';
    final k = _apiKey!;
    if (k.length <= 4) return '••••';
    return '••••••••••${k.substring(k.length - 4)}';
  }

  /// Load saved key from SharedPreferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_keyPref);
    notifyListeners();
  }

  /// Save the key locally and optionally validate it.
  Future<bool> save(String key, {bool validate = true}) async {
    _apiKey = key.trim();
    _isValid = null;
    _validationError = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPref, _apiKey!);
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
      final error = await gemini.testKeyWithError();
      if (error == null) {
        _isValid = true;
        _validationError = null;
        _isValidating = false;
        notifyListeners();
        return true;
      } else {
        _isValid = false;
        _validationError = error;
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

  /// Delete the key.
  Future<void> delete() async {
    _apiKey = null;
    _isValid = null;
    _validationError = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPref);
    notifyListeners();
  }
}
