import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'navigation_subscriber.dart';
import 'precondition.dart';
import 'router.dart';

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
    return shouldNotify != null
        ? shouldNotify(oldWidget.bloc, bloc)
        : oldWidget.bloc != bloc;
  }

  static B of<B extends Bloc>(BuildContext context, {bool listen = false}) {
    final Provider<B> provider = listen
        ? context.dependOnInheritedWidgetOfExactType<Provider<B>>()
        : context
            .getElementForInheritedWidgetOfExactType<Provider<B>>()
            ?.widget;
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
    this.routerPrecondition,
  })  : assert(child != null),
        assert(create != null),
        super(key: key);

  final B Function() create;
  final Widget child;
  final Router router;
  final Precondition<RouteSettings> routerPrecondition;
  final UpdateShouldNotify<B> shouldNotify;

  @override
  _BlocProviderState<B> createState() => _BlocProviderState<B>();
}

class _BlocProviderState<B extends Bloc> extends State<BlocProvider<B>>
    with NavigationSubscriber<B, BlocProvider<B>> {
  B _bloc;

  @override
  void initState() {
    _bloc ??= widget.create();
    subscribe();
    super.initState();
  }

  @override
  void didUpdateWidget(BlocProvider<B> oldWidget) {
    super.didUpdateWidget(oldWidget);
    subscribe();
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
    unsubscribe();
    _bloc?.dispose();
    super.dispose();
  }

  @override
  get precondition => widget.routerPrecondition;

  @override
  B get bloc => _bloc;

  @override
  get router => widget.router;
}
