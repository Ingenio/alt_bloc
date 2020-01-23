import 'dart:async';

import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'router.dart';

mixin NavigationSubscriber<B extends Bloc, T extends StatefulWidget> on State<T> {


//  todo how to add precondition here???
  StreamSubscription<RouteSettings> subscription;

  void subscribe(Router router, B bloc) {
    if (router != null) {
      final navigateTo = (RouteSettings settings) => router(context, settings.name, settings.arguments);
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
