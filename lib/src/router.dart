import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'bloc_holder.dart';
import 'bloc_provider.dart';
import 'navigation_subscriber.dart';


typedef Router = Function(BuildContext context, String name, dynamic args);

class RouteListener<B extends Bloc> extends BlocHolder<B> {
  RouteListener({Key key, @required this.child, this.router, B bloc})
      : assert(child != null),
        super(key: key, bloc: bloc);

  final Router router;
  final Widget child;

  @override
  State<StatefulWidget> createState() => _RouteListenerState<B>();
}

class _RouteListenerState<B extends Bloc> extends BlocHolderState<B, RouteListener<B>>
    with NavigationSubscriber<B, RouteListener<B>>{

  @override
  void initState() {
    super.initState();
    subscribeOnBlocNavigation(widget.router, bloc);
  }

  @override
  void onBlocChanged(B bloc) {
    super.onBlocChanged(bloc);
    if (subscription != null) {
      unsubscribeFromBlocNavigation();
    }
    subscribeOnBlocNavigation(widget.router, bloc);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
