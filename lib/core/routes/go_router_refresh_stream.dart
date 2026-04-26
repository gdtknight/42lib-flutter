import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapter that turns a [Stream] into a [ChangeNotifier] so it can be passed
/// to `GoRouter`'s `refreshListenable`. Notifies listeners on every emission,
/// triggering re-evaluation of the router's `redirect` callback.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
