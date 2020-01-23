import 'dart:async';

import 'package:alt_bloc/src/precondition.dart';
import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'router.dart';

mixin NavigationSubscriber<B extends Bloc, T extends StatefulWidget> on State<T> {

  StreamSubscription<RouteSettings> subscription;
  Precondition<RouteSettings> get precondition;
  B get bloc;
  Router get router;
  RouteSettings _previousSettings;

  void subscribe() {
    if (router != null) {
      final navigateTo = (RouteSettings settings) {
        if (precondition?.call(_previousSettings, settings) ?? true) {
          router(context, settings.name, settings.arguments);
        }
      };
      if (subscription == null) {
        subscription = bloc.listenNavigation(navigateTo);
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
