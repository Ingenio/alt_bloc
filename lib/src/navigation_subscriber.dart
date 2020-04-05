import 'dart:async';

import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'precondition.dart';
import 'router.dart';

mixin NavigationSubscriber<B extends Bloc, T extends StatefulWidget>
    on State<T> {
  StreamSubscription<RouteData> subscription;
  Precondition<RouteSettings> get precondition;
  B get bloc;
  Router get router;
  var _previousSettings = const RouteSettings();

  void subscribe() {
    if (router != null) {
      final navigateTo = (RouteData data) {
        if (precondition?.call(_previousSettings, data.settings) ?? true) {
          final result =
              router(context, data.settings.name, data.settings.arguments);
          data.resultConsumer(result);
          _previousSettings = data.settings;
        }
      };
      if (subscription == null) {
        subscription = bloc.navigationStream.listen(navigateTo);
      } else {
        subscription.onData(navigateTo);
      }
    }
  }

  void unsubscribe() {
    subscription?.cancel();
    subscription = null;
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }
}
