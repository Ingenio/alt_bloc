import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'bloc_widget.dart';
import 'precondition.dart';
import 'router.dart';

/// Signature of predicate function that use to compare [Bloc] objects.
typedef UpdateShouldNotify<T> = bool Function(T previous, T current);

/// [InheritedWidget] that encapsulated by [BlocProvider] and allow [BlocProvider.child] widgets tree to obtain the
/// [Bloc] object.
class Provider<B extends Bloc> extends InheritedWidget {
  const Provider._({
    Key? key,
    required this.bloc,
    required Widget child,
    this.shouldNotify,
  }) : super(key: key, child: child);

  final B bloc;
  final UpdateShouldNotify<B>? shouldNotify;

  @override
  bool updateShouldNotify(Provider<B> oldWidget) {
    return shouldNotify?.call(oldWidget.bloc, bloc) ?? oldWidget.bloc != bloc;
  }

  /// Static function that returns [Bloc] of type `B`.
  ///
  /// If [listen] defines as `true`, each time when [Bloc] object changes, this [context] is rebuilt. Custom
  /// Blocs comparison rules could be defined in [BlocProvider.shouldNotify] function.
  static B of<B extends Bloc>(BuildContext context, {bool listen = false}) {
    final Provider<B>? provider = listen
        ? context.dependOnInheritedWidgetOfExactType<Provider<B>>()
        : context.getElementForInheritedWidgetOfExactType<Provider<B>>()?.widget
            as Provider<B>;
    return provider?.bloc ?? (throw ProviderNotFoundError());
  }
}

class ProviderNotFoundError extends Error {
  @override
  String toString() => 'Provider was not found. Check that you have added '
      'BlocProvider to Widgets hierarchy tree!';
}

/// [Widget] that responsible to create the [Bloc] with help of [create] function. Accepts any [Widget] as child and
/// provides the ability for child to obtain the [Bloc].
///
/// Function [shouldNotify] define whether that widgets that inherit from this widget should be rebuilt if [Bloc] was
/// changed.
///
/// [BlocProvider] could subscribe on [Bloc.navigationStream] and receives navigation events if [router] function will
/// be defined, similar as [RouteListener].
/// ```dart
/// class CounterScreen extends StatelessWidget {
///
///   @override
///   Widget build(BuildContext context) {
///     return BlocProvider<CounterBloc>(
///       routerPrecondition: (prevSettings, settings) => (settings.arguments as int) % 5 == 0,
///       create: () => CounterBloc(),
///       child: CounterLayout(title: 'Bloc Demo Home Page'),
///       router: (context, name, args) {
///         return showDialog(
///             context: context,
///             builder: (_) {
///               return WillPopScope(
///                   child: AlertDialog(
///                     title: Text('Congratulations! You clicked $args times'),
///                   ),
///                   onWillPop: () async {
///                     Navigator.of(context).pop('Dialog with $args clicks has been closed');
///                     return false;
///                   }
///               );
///             }
///         );
///       },
///     );
///   }
/// }
/// ```

class BlocProvider<B extends Bloc> extends BlocSubscriber<B, RouteData> {
  const BlocProvider({
    Key? key,
    required this.child,
    required this.create,
    this.router,
    this.shouldNotify,
    Precondition<RouteData>? routerPrecondition,
  }) : super(key: key, precondition: routerPrecondition);

  final B Function() create;
  final Widget child;
  final BlocRouter? router;
  final UpdateShouldNotify<B>? shouldNotify;

  @override
  _BlocProviderState<B> createState() => _BlocProviderState<B>();
}

class _BlocProviderState<B extends Bloc>
    extends BlocSubscriberState<B, RouteData, BlocProvider<B>> {
  late final B _bloc;

  @override
  void initState() {
    _bloc = widget.create();
    super.initState();
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
  Stream<RouteData>? get stream =>
      widget.router == null ? null : _bloc.navigationStream;

  @override
  void onNewState(RouteData state) {
    final result = widget.router
        ?.call(context, state.settings.name, state.settings.arguments);
    state.resultConsumer(result);
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }
}
