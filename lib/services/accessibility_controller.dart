import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityController extends ChangeNotifier {
  static const _kHighContrast = 'a11y_high_contrast';
  static const _kColorblind = 'a11y_colorblind';
  static const _kBold = 'a11y_bold';
  static const _kTextScale = 'a11y_text_scale';

  bool _highContrast = false;
  bool _colorblindFriendly = false;
  bool _boldLabels = false;
  int _textScaleIndex = 0;

  bool get highContrast => _highContrast;
  bool get colorblindFriendly => _colorblindFriendly;
  bool get boldLabels => _boldLabels;
  int get textScaleIndex => _textScaleIndex;

  double get textScaleLinear {
    switch (_textScaleIndex) {
      case 1:
        return 1.12;
      case 2:
        return 1.28;
      default:
        return 1.0;
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _highContrast = prefs.getBool(_kHighContrast) ?? false;
    _colorblindFriendly = prefs.getBool(_kColorblind) ?? false;
    _boldLabels = prefs.getBool(_kBold) ?? false;
    _textScaleIndex = prefs.getInt(_kTextScale)?.clamp(0, 2) ?? 0;
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHighContrast, value);
  }

  Future<void> setColorblindFriendly(bool value) async {
    _colorblindFriendly = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kColorblind, value);
  }

  Future<void> setBoldLabels(bool value) async {
    _boldLabels = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBold, value);
  }

  Future<void> setTextScaleIndex(int index) async {
    _textScaleIndex = index.clamp(0, 2);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTextScale, _textScaleIndex);
  }
}
