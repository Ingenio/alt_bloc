import 'dart:async';

import 'package:flutter/widgets.dart';

// todo move bloc to separate file
// todo change StreamBuilder with own solution
// todo write tests

extension _BlocStreamController<T> on StreamController<T> {

  void addIfNotClosed(T event) {
    if (!isClosed) {
      sink.add(event);
    }
  }

}

/// Business Logic Component
abstract class Bloc<NS> {
  final _stateHolders = <Type, _StateHolder<dynamic>>{};
  final _navigationController = StreamController<NS>();

  void addNavigation(NS state) {
    _navigationController.sink.add(state);
  }

  void dispose() {
    _stateHolders.forEach((_, holder) => holder.controller.close());
    _stateHolders.clear();
    _navigationController.close();
  }

  void registerState<US>({bool isBroadcast = false, US initialState}) {
    if (_stateHolders.containsKey(US)) {
      throw FlutterError('UI state with type $US already has been registered');
    } else {
      final stateHolder = _StateHolder<US>(isBroadcast ? StreamController<US>.broadcast() : StreamController<US>(),
          initialState: initialState);
      _stateHolders[US] = stateHolder;
    }
  }

  void addState<US>(US uiState) {
    US state = uiState;
    _stateHolders[US].controller.add(state);
  }
}

class _StateHolder<US> {
  final StreamController<US> controller;

  final US initialState;

  _StateHolder(this.controller, {this.initialState});
}

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
//    final type = _getType<Provider<B>>();
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribeOnNavigationStream(widget.listener);
  }

  void _subscribeOnNavigationStream(NavigationListener<NS> listener) {
    if (listener != null) {
      final navigate = (state) => listener(context, state);
      if (_subscription == null) {
        _subscription = _navigationStream.listen(navigate);
      } else {
        _subscription.onData(navigate);
      }
    }
  }

  Stream<NS> get _navigationStream => _bloc._navigationController.stream;

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
  _StateHolder<US> _stateHolder;

  @override
  void initState() {
    super.initState();
    final bloc = widget.bloc ?? Provider.of<B>(context);
    _stateHolder = bloc?._stateHolders[US];
  }

  @override
  Widget build(BuildContext context) {
    final stream = _stateHolder.controller.stream;
    return StreamBuilder<US>(
      initialData: _stateHolder.initialState,
      stream: stream.isBroadcast ? stream.asBroadcastStream() : stream,
      builder: (context, snapshot) => widget.builder(context, snapshot.data),
    );
  }

  @override
  void didUpdateWidget(BlocBuilder<B, US> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc ?? Provider.of<B>(context);
    final currentBloc = widget.bloc ?? oldBloc;
    if (oldBloc != currentBloc) {
      final bloc = widget.bloc ?? Provider.of<B>(context);
      _stateHolder = bloc?._stateHolders[US];
    }
  }
}
