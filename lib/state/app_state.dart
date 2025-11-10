import 'package:flutter/widgets.dart';

class AppState extends ChangeNotifier {
  AppState();

  Locale _locale = const Locale('es');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale == locale) {
      return;
    }
    _locale = locale;
    notifyListeners();
  }
}
