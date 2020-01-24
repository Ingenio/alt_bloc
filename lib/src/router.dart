import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'bloc_holder.dart';
import 'navigation_subscriber.dart';
import 'precondition.dart';


typedef Router = Function(BuildContext context, String name, dynamic args);

class RouteListener<B extends Bloc> extends BlocHolder<B> {
  const RouteListener({Key key, @required this.child, this.router, B bloc, this.precondition})
      : assert(child != null),
        super(key: key, bloc: bloc);

  final Router router;
  final Widget child;
  final Precondition<RouteSettings> precondition;

  @override
  State<StatefulWidget> createState() => _RouteListenerState<B>();
}

class _RouteListenerState<B extends Bloc> extends BlocHolderState<B, RouteListener<B>>
    with NavigationSubscriber<B, RouteListener<B>>{

  @override
  void initState() {
    super.initState();
    subscribe();
  }

  @override
  Future<void> onBlocChanged(B bloc) async {
    super.onBlocChanged(bloc);
    unsubscribe();
    subscribe();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  get precondition => widget.precondition;

  @override
  Router get router => widget.router;
}
