import 'dart:async';

class CustomZoneEvents {
  CustomZoneEvents._();

  static final CustomZoneEvents instance = CustomZoneEvents._();

  final StreamController<void> _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notifyChanged() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}

