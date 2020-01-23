import 'package:alt_bloc/src/route_state.dart';
import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'bloc_holder.dart';
import 'navigation_subscriber.dart';
import 'precondition.dart';


typedef Router = Function(BuildContext context, String name, dynamic args);

class RouteListener<B extends Bloc> extends BlocHolder<B> {
  RouteListener({Key key, @required this.child, this.router, B bloc, this.precondition})
      : assert(child != null),
        super(key: key, bloc: bloc);

  final Router router;
  final Widget child;
  final Precondition<RouteState> precondition;

  @override
  State<StatefulWidget> createState() => _RouteListenerState<B>();
}

class _RouteListenerState<B extends Bloc> extends BlocHolderState<B, RouteListener<B>>
    with NavigationSubscriber<B, RouteListener<B>>{

  @override
  void initState() {
    super.initState();
    subscribe(widget.router, bloc);
  }

  @override
  Future<void> onBlocChanged(B bloc) async {
    super.onBlocChanged(bloc);
    unsubscribe();
    subscribe(widget.router, bloc);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
