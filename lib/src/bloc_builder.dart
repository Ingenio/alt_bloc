import 'dart:async';

import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'bloc_provider.dart';

typedef BlocWidgetBuilder<S> = Widget Function(BuildContext context, S state);

/// Bloc Builder that observe Bloc by subscribing on StreamController.
class BlocBuilder<B extends Bloc, S> extends StatefulWidget {
  final BlocWidgetBuilder<S> builder;
  final B bloc;

  const BlocBuilder({Key key, this.bloc, @required this.builder}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _BlocBuilderState<B, S>();
}

class _BlocBuilderState<B extends Bloc, S> extends State<BlocBuilder<B, S>> {
  StreamSubscription<S> _subscription;
  S _data;
  B _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? Provider.of<B>(context);
    _data = _bloc?.initialState<S>();
    _subscribe();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _data);

  @override
  void didUpdateWidget(BlocBuilder<B, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc;
    final currentBloc = widget.bloc ?? Provider.of<B>(context);
    if (oldBloc != currentBloc) {
      _bloc = currentBloc;
      if (_subscription != null) {
        _unsubscribe();
      }
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription = _bloc?.listenState<S>((S data) {
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
