import 'dart:async';
import 'package:alt_bloc/src/route_state.dart';
import 'package:alt_bloc/src/router.dart';
import 'package:flutter/widgets.dart';
import 'bloc.dart';

// todo write tests

typedef UpdateShouldNotify<T> = bool Function(T previous, T current);

/// InheritedWidget that responsible for providing Bloc instance.
class Provider<B extends Bloc> extends InheritedWidget {
  const Provider._({Key key, @required B bloc, Widget child, this.shouldNotify})
      : assert(bloc != null),
        bloc = bloc,
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

/// Widget that responsible for creation of Bloc, should be placed in root of UI widgets tree.
class BlocProvider<B extends Bloc> extends StatefulWidget {
  const BlocProvider({
    Key key,
    @required this.child,
    @required this.create,
    this.router,
    this.shouldNotify,
  })  : assert(child != null),
        assert(create != null),
        super(key: key);

  final B Function() create;
  final Widget child;
  final Router router;
  final UpdateShouldNotify<B> shouldNotify;

  @override
  _BlocProviderState<B> createState() => _BlocProviderState<B>();
}

class _BlocProviderState<B extends Bloc> extends State<BlocProvider<B>> {
  B _bloc;
  StreamSubscription<RouteState> _subscription;

  @override
  void initState() {
    if (widget.create != null) {
      _bloc ??= widget.create();
    }
    super.initState();
    _subscribeOnNavigationStream(widget.router);
  }

  @override
  void didUpdateWidget(BlocProvider<B> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _subscribeOnNavigationStream(widget.router);
  }

  void _subscribeOnNavigationStream(Router router) {
    if (router != null) {
      final navigate = (RouteState state) => router(context, state.name, state.args);
      if (_subscription == null) {
        _subscription = _bloc.listenNavigation(navigate);
      } else {
        _subscription.onData(navigate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Provider._(
      bloc: _bloc,
      child: widget.child,
      shouldNotify: widget.shouldNotify,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _bloc?.dispose();
    super.dispose();
  }
}
