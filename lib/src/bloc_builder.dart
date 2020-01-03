import 'dart:async';

import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'bloc_provider.dart';

typedef BlocWidgetBuilder<US> = Widget Function(BuildContext context, US state);

/// Bloc Builder that observe Bloc by subscribing on StreamController.
class BlocBuilder<B extends Bloc, US> extends StatefulWidget {
  final BlocWidgetBuilder<US> builder;
  final B bloc;

  const BlocBuilder({this.bloc, @required this.builder});

  @override
  State<StatefulWidget> createState() => _BlocBuilderState<B, US>();
}

class _BlocBuilderState<B extends Bloc, US> extends State<BlocBuilder<B, US>> {

  StreamSubscription<US> _subscription;
  US _data;
  B _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? Provider.of<B>(context);
    _data = _bloc?.initialState<US>();
    _subscribe();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _data);

  @override
  void didUpdateWidget(BlocBuilder<B, US> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc ?? Provider.of<B>(context);
    final currentBloc = widget.bloc ?? oldBloc;
    if (oldBloc != currentBloc) {
      _bloc = widget.bloc ?? Provider.of<B>(context);
      if (_subscription != null) {
        _unsubscribe();
      }
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription = _bloc?.listenState<US>((US data) {
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
