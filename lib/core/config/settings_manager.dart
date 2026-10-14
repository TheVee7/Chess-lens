import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';

/// Persisted app settings.
class SettingsManager extends ChangeNotifier {
  int _analysisTimeMs = AppConfig.defaultAnalysisTimeMs;
  int _engineDepth = AppConfig.defaultEngineDepth;
  int _multiPv = AppConfig.defaultMultiPV;
  int _hashMemory = AppConfig.defaultHashMemory;
  int _cpuThreads = defaultCpuThreads();
  bool _showBestMoveArrow = AppConfig.defaultShowBestMoveArrow;
  bool _autoAnalyze = AppConfig.defaultAutoAnalyze;

  int get analysisTimeMs => _analysisTimeMs;
  int get engineDepth => _engineDepth;
  int get multiPv => _multiPv;
  int get hashMemory => _hashMemory;
  int get cpuThreads => _cpuThreads;
  bool get showBestMoveArrow => _showBestMoveArrow;
  bool get autoAnalyze => _autoAnalyze;

  /// Returns detected CPU cores count, or 2 if detection fails.
  int get deviceCores {
    try {
      return Platform.numberOfProcessors;
    } catch (_) {
      return 2;
    }
  }

  /// Default CPU threads for new installations, subject to device capabilities.
  static int defaultCpuThreads() {
    try {
      final cores = Platform.numberOfProcessors;
      if (cores < 2) return 1;
      return 2;
    } catch (_) {
      return 2;
    }
  }

  set analysisTimeMs(int v) {
    final clamped = v.clamp(
      AppConfig.minAnalysisTimeMs,
      AppConfig.maxAnalysisTimeMs,
    );
    if (_analysisTimeMs == clamped) return;
    _analysisTimeMs = clamped;
    _persist();
    notifyListeners();
  }

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

  set hashMemory(int v) {
    if (!AppConfig.hashOptions.contains(v)) return;
    if (_hashMemory == v) return;
    _hashMemory = v;
    _persist();
    notifyListeners();
  }

  set cpuThreads(int v) {
    if (!AppConfig.threadOptions.contains(v)) return;
    if (_cpuThreads == v) return;
    _cpuThreads = v;
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

    // Load and validate analysis time per position
    final storedTime = prefs.getInt('analysis_time_ms');
    if (storedTime != null) {
      if (storedTime >= AppConfig.minAnalysisTimeMs &&
          storedTime <= AppConfig.maxAnalysisTimeMs) {
        _analysisTimeMs = storedTime;
      } else {
        _analysisTimeMs = AppConfig.defaultAnalysisTimeMs;
      }
    } else {
      // Migrate from legacy depth if present without letting it override if analysis_time_ms is already set
      final legacyDepth = prefs.getInt('engine_depth');
      if (legacyDepth != null) {
        if (legacyDepth <= 8) {
          _analysisTimeMs = AppConfig.quickAnalysisTimeMs;
        } else if (legacyDepth >= 15) {
          _analysisTimeMs = AppConfig.thoroughAnalysisTimeMs;
        } else {
          _analysisTimeMs = AppConfig.balancedAnalysisTimeMs;
        }
      } else {
        _analysisTimeMs = AppConfig.defaultAnalysisTimeMs;
      }
      await prefs.setInt('analysis_time_ms', _analysisTimeMs);
    }

    _engineDepth = prefs.getInt('engine_depth') ?? AppConfig.defaultEngineDepth;
    _multiPv = prefs.getInt('multi_pv') ?? AppConfig.defaultMultiPV;
    _showBestMoveArrow =
        prefs.getBool('show_best_move_arrow') ??
        AppConfig.defaultShowBestMoveArrow;
    _autoAnalyze =
        prefs.getBool('auto_analyze') ?? AppConfig.defaultAutoAnalyze;

    // Validate and load Hash Memory
    final storedHash = prefs.getInt('hash_memory');
    if (storedHash != null && AppConfig.hashOptions.contains(storedHash)) {
      _hashMemory = storedHash;
    } else {
      _hashMemory = AppConfig.defaultHashMemory;
    }

    // Validate and load CPU Threads
    final storedThreads = prefs.getInt('cpu_threads');
    if (storedThreads != null &&
        AppConfig.threadOptions.contains(storedThreads)) {
      _cpuThreads = storedThreads;
    } else {
      _cpuThreads = defaultCpuThreads();
    }

    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('analysis_time_ms', _analysisTimeMs);
    await prefs.setInt('engine_depth', _engineDepth);
    await prefs.setInt('multi_pv', _multiPv);
    await prefs.setBool('show_best_move_arrow', _showBestMoveArrow);
    await prefs.setBool('auto_analyze', _autoAnalyze);
    await prefs.setInt('hash_memory', _hashMemory);
    await prefs.setInt('cpu_threads', _cpuThreads);
  }
}
