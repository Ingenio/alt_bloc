import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'bloc_holder.dart';
import 'navigation_subscriber.dart';
import 'precondition.dart';

/// Signature of function that use to listen for navigation events and return navigation result.
typedef Router<Result> = Future<Result> Function(
    BuildContext context, String name, dynamic args);

/// [Widget] that subscribes on [Bloc.navigationStream], listen for navigation actions and handle them.
///  If [bloc] was not provided [Provider.of] will be used by default.
///
/// **WARNING!!!** Potentially few [RouteListener] widgets could be subscribed on the same stream, so same navigation
/// event could be handled several times. We recommend to use [precondition] to avoid such situation.
///
/// ```dart
/// RouteListener<CounterBloc>(
///   bloc: CounterBloc(),
///   child: CounterLayout(title: 'Bloc Demo Home Page'),
///   precondition: (prevSettings, settings) => (settings.arguments as int) % 5 == 0,
///   router: (context, name, args) {
///     return showDialog(
///         context: context,
///         builder: (_) {
///           return WillPopScope(
///               child: AlertDialog(
///                 title: Text('Congratulations! You clicked $args times'),
///               ),
///               onWillPop: () async {
///                 Navigator.of(context).pop('Dialog with $args clicks has been closed');
///                 return false;
///               });
///         });
///   },
/// )
/// ```
class RouteListener<B extends Bloc> extends BlocHolder<B> {

  const RouteListener(
      {Key key, @required this.child, this.router, B bloc, this.precondition})
      : assert(child != null),
        super(key: key, bloc: bloc);

  final Router router;
  final Widget child;
  final Precondition<RouteSettings> precondition;

  @override
  State<StatefulWidget> createState() => _RouteListenerState<B>();
}

class _RouteListenerState<B extends Bloc>
    extends BlocHolderState<B, RouteListener<B>>
    with NavigationSubscriber<B, RouteListener<B>> {
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
