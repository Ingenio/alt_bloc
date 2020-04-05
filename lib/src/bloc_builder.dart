import 'dart:async';

import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'bloc_holder.dart';
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
class BlocBuilder<B extends Bloc, S> extends BlocHolder<B> {
  final BlocWidgetBuilder<S> builder;
  final Precondition<S> precondition;

  const BlocBuilder(
      {Key key, B bloc, @required this.builder, this.precondition})
      : super(key: key, bloc: bloc);

  @override
  State<StatefulWidget> createState() => _BlocBuilderState<B, S>();
}

class _BlocBuilderState<B extends Bloc, S>
    extends BlocHolderState<B, BlocBuilder<B, S>> {
  StreamSubscription<S> _subscription;
  S _state;
  S _previousState;

  @override
  void initState() {
    super.initState();
    _state = bloc.initialState<S>();
    _subscribe();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _state);

  @override
  void onBlocChanged(B bloc) {
    super.onBlocChanged(bloc);
    _unsubscribe();
    _subscribe();
  }

  void _subscribe() {
    _subscription = bloc.getStateStream<S>().listen((S state) {
      if (widget.precondition?.call(_previousState, state) ?? true) {
        setState(() {
          _previousState = _state;
          _state = state;
        });
      }
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }
}
