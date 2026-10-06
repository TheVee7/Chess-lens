import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the Gemini API key in secure local storage.
class ApiKeyManager extends ChangeNotifier {
  static const _keyPref = 'gemini_api_key';

  String? _apiKey;
  String? get apiKey => _apiKey;
  bool get hasKey => _apiKey != null && _apiKey!.isNotEmpty;

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

  /// Save the key locally.
  Future<void> save(String key) async {
    _apiKey = key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPref, _apiKey!);
    notifyListeners();
  }

  /// Delete the key.
  Future<void> delete() async {
    _apiKey = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPref);
    notifyListeners();
  }
}
