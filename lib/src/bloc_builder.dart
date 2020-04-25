import 'dart:async';

import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'bloc_widget.dart';
import 'precondition.dart';

/// Signature of function that use to build and return [Widget] depending on [state].
typedef BlocWidgetBuilder<S> = Widget Function(BuildContext context, S state);

/// [Widget] that accept [Bloc] of type `B` and subscribes on states stream of type `S`.
///
/// If [Bloc] was not provided, so [Provider.of] uses by default.
/// Function [builder] calls each time when new state was added to stream and returns Widget depending on state.
/// [precondition] allow to filter stats that will be delivered to [builder].
///
/// ```dart
/// BlocBuilder<CounterBloc, int>(
///     bloc: CounterBloc(),
///     precondition: (prevCount, count) => count % 2 == 0,
///     builder: (_, count) => Text('$count');
/// )
/// ```
class BlocBuilder<B extends Bloc, S> extends BlocWidget<B, S> {
  const BlocBuilder(
      {Key key, B bloc, @required this.builder, Precondition<S> precondition})
      : super(key: key, bloc: bloc, precondition: precondition);

  final BlocWidgetBuilder<S> builder;

  @override
  State<StatefulWidget> createState() => _BlocBuilderState<B, S>();
}

class _BlocBuilderState<B extends Bloc, S>
    extends BlocWidgetState<B, S, BlocBuilder<B, S>> {

  @override
  S get initialState => bloc.initialState<S>();

  @override
  void onNewState(S state) {
    setState(() {});
  }

  @override
  Stream<S> get stream => bloc.getStateStream<S>();

  @override
  Widget build(BuildContext context) => widget.builder(context, currentState);
}
