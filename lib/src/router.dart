import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'bloc_widget.dart';
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
///   precondition: (prevData, data) => (data.settings.arguments as int) % 5 == 0,
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
class RouteListener<B extends Bloc> extends BlocWidget<B, RouteData> {
  const RouteListener(
      {Key key,
      @required this.child,
      @required this.router,
      B bloc,
      Precondition<RouteData> precondition})
      : assert(child != null),
        assert(router != null),
        super(key: key, bloc: bloc, precondition: precondition);

  final Router router;
  final Widget child;

  @override
  State<StatefulWidget> createState() => _RouteListenerState<B>();
}

class _RouteListenerState<B extends Bloc>
    extends BlocWidgetState<B, RouteData, RouteListener<B>> {
  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void onNewState(RouteData state) {
    final result =
        widget.router(context, state.settings.name, state.settings.arguments);
    state.resultConsumer(result);
  }

  @override
  Stream<RouteData> get stream => bloc.navigationStream;
}
