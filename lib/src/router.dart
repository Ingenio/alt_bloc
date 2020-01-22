import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'bloc_provider.dart';
import 'navigation_subscriber.dart';


typedef Router = Function(BuildContext context, String name, dynamic args);

class RouteListener<B extends Bloc> extends StatefulWidget {
  RouteListener({Key key, @required this.child, this.router, this.bloc})
      : assert(child != null),
        super(key: key);

  final Router router;
  final Widget child;
  final B bloc;

  @override
  State<StatefulWidget> createState() => _RouteListenerState<B>();
}

class _RouteListenerState<B extends Bloc> extends State<RouteListener> with NavigationSubscriber<B, RouteListener>{

  B _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? Provider.of<B>(context);
    subscribeOnBlocNavigation(widget.router, _bloc);
  }

  @override
  void didUpdateWidget(RouteListener<Bloc> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc;
    final currentBloc = widget.bloc ?? Provider.of<B>(context);
    if (currentBloc != oldBloc) {
      _bloc = currentBloc;
      if (subscription != null) {
        unsubscribeFromBlocNavigation();
      }
      subscribeOnBlocNavigation(widget.router, _bloc);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
