import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';

/// Persisted app settings.
class SettingsManager extends ChangeNotifier {
  int _engineDepth = AppConfig.defaultEngineDepth;
  int _multiPv = AppConfig.defaultMultiPV;
  bool _showBestMoveArrow = AppConfig.defaultShowBestMoveArrow;
  bool _autoAnalyze = AppConfig.defaultAutoAnalyze;

  int get engineDepth => _engineDepth;
  int get multiPv => _multiPv;
  bool get showBestMoveArrow => _showBestMoveArrow;
  bool get autoAnalyze => _autoAnalyze;

  set engineDepth(int v) {
    _engineDepth = v.clamp(1, 30);
    _persist();
    notifyListeners();
  }

  set multiPv(int v) {
    _multiPv = v.clamp(1, 5);
    _persist();
    notifyListeners();
  }

  set showBestMoveArrow(bool v) {
    _showBestMoveArrow = v;
    _persist();
    notifyListeners();
  }

  set autoAnalyze(bool v) {
    _autoAnalyze = v;
    _persist();
    notifyListeners();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _engineDepth = prefs.getInt('engine_depth') ?? AppConfig.defaultEngineDepth;
    _multiPv = prefs.getInt('multi_pv') ?? AppConfig.defaultMultiPV;
    _showBestMoveArrow =
        prefs.getBool('show_best_move_arrow') ?? AppConfig.defaultShowBestMoveArrow;
    _autoAnalyze = prefs.getBool('auto_analyze') ?? AppConfig.defaultAutoAnalyze;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('engine_depth', _engineDepth);
    await prefs.setInt('multi_pv', _multiPv);
    await prefs.setBool('show_best_move_arrow', _showBestMoveArrow);
    await prefs.setBool('auto_analyze', _autoAnalyze);
  }
}
