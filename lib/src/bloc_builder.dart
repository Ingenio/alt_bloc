import 'dart:async';

import 'package:alt_bloc/src/bloc_holder.dart';
import 'package:flutter/widgets.dart';

import 'bloc.dart';

typedef BlocWidgetBuilder<S> = Widget Function(BuildContext context, S state);

/// Bloc Builder that observe Bloc by subscribing on StreamController.
class BlocBuilder<B extends Bloc, S> extends BlocHolder<B> {

  final BlocWidgetBuilder<S> builder;

  const BlocBuilder({Key key, B bloc, @required this.builder}) : super(key: key, bloc: bloc);

  @override
  State<StatefulWidget> createState() => _BlocBuilderState<B, S>();
}

class _BlocBuilderState<B extends Bloc, S> extends BlocHolderState<B, BlocBuilder<B, S>> {

  StreamSubscription<S> _subscription;
  S _data;

  @override
  void initState() {
    super.initState();
    _data = bloc?.initialState<S>();
    _subscribe();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _data);

  @override
  void onBlocChanged(B bloc) {
    super.onBlocChanged(bloc);
    _unsubscribe();
    _subscribe();
  }

  void _subscribe() {
    _subscription = bloc?.listenState<S>((S data) {
      setState(() {
        _data = data;
      });
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
