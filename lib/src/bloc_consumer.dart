import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'bloc_widget.dart';
import 'precondition.dart';

typedef Consumer<T> = void Function(T state);

/// [Widget] that accept [Bloc] of type `B` and subscribes on states stream of type `S`.
///
/// If [Bloc] was not provided, so [Provider.of] uses by default.
/// [consumer] function will be triggered each time on new state.
class BlocConsumer<B extends Bloc, S> extends BlocWidget<B, S> {
  const BlocConsumer(
      {Key? key,
      required this.child,
      required this.consumer,
      B? bloc,
      Precondition<S>? precondition})
      : super(key: key, bloc: bloc, precondition: precondition);

  final Widget child;
  final Consumer<S> consumer;

  @override
  State<StatefulWidget> createState() => _BlocConsumerState<B, S>();
}

class _BlocConsumerState<B extends Bloc, S>
    extends BlocWidgetState<B, S, BlocConsumer<B, S>> {

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void onNewState(S state) => widget.consumer.call(state);

  @override
  Stream<S>? get stream => bloc.getStateStream<S>();
}
