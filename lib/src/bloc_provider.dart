import 'dart:async';
import 'package:flutter/widgets.dart';
import 'bloc.dart';

// todo write tests

typedef UpdateShouldNotify<T> = bool Function(T previous, T current);

/// InheritedWidget that responsible for providing Bloc instance.
class Provider<B extends Bloc> extends InheritedWidget {
  const Provider._({Key key, @required B bloc, Widget child, this.shouldNotify})
      : bloc = bloc,
        super(key: key, child: child);

  final B bloc;
  final UpdateShouldNotify<B> shouldNotify;

  @override
  bool updateShouldNotify(Provider oldWidget) {
    return shouldNotify != null ? shouldNotify(oldWidget.bloc, bloc) : oldWidget.bloc != bloc;
  }

  static B of<B extends Bloc>(BuildContext context, {bool listen = false}) {
    final Provider<B> provider = listen
        ? context.dependOnInheritedWidgetOfExactType<Provider<B>>()
        : context.getElementForInheritedWidgetOfExactType<Provider<B>>()?.widget;
    return provider?.bloc;
  }
}

typedef NavigationListener<NS> = void Function(BuildContext, NS);

/// Widget that responsible for creation of Bloc, should be placed in root of UI widgets tree.
class BlocProvider<B extends Bloc<NS>, NS> extends StatefulWidget {
  const BlocProvider({
    Key key,
    @required this.child,
    @required this.bloc,
    this.listener,
    this.shouldNotify,
  }) : super(key: key);

  final B Function() bloc;
  final Widget child;
  final NavigationListener<NS> listener;
  final UpdateShouldNotify<B> shouldNotify;

  @override
  _BlocProviderState<B, NS> createState() => _BlocProviderState<B, NS>();
}

class _BlocProviderState<B extends Bloc<NS>, NS> extends State<BlocProvider<B, NS>> {
  B _bloc;
  StreamSubscription<NS> _subscription;

  @override
  void initState() {
    if (widget.bloc != null) {
      _bloc ??= widget.bloc();
    }
    super.initState();
    _subscribeOnNavigationStream(widget.listener);
  }

  @override
  void didUpdateWidget(BlocProvider<B, NS> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _subscribeOnNavigationStream(widget.listener);
  }


  void _subscribeOnNavigationStream(NavigationListener<NS> listener) {
    if (listener != null) {
      final navigate = (NS state) => listener(context, state);
      if (_subscription == null) {
        _subscription = _bloc.listenNavigation(navigate);
      } else {
        _subscription.onData(navigate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Provider._(bloc: _bloc, child: widget.child, shouldNotify: widget.shouldNotify,);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _bloc?.dispose();
    super.dispose();
  }
}

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
