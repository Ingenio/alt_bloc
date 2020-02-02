import 'dart:async';

import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'bloc_holder.dart';
import 'precondition.dart';

typedef BlocWidgetBuilder<S> = Widget Function(BuildContext context, S state);

/// Bloc Builder that observe Bloc by subscribing on StreamController.
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
    _subscription = bloc.listenState<S>((S state) {
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
