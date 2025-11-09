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

class AppStateProvider extends InheritedNotifier<AppState> {
  const AppStateProvider({
    super.key,
    required AppState appState,
    required Widget child,
  }) : super(notifier: appState, child: child);

  static AppState of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<AppStateProvider>();
    assert(provider != null, 'AppStateProvider not found in context');
    return provider!.notifier!;
  }

  @override
  bool updateShouldNotify(covariant AppStateProvider oldWidget) {
    return notifier != oldWidget.notifier;
  }
}


