import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

/// Business Logic Component (BLoC).
///
/// The class that implements the core business logic, and that should be placed between UI and data source. BLoC
/// accepts UI actions from the widget and in return notifies the widget's about changes in UI state or initiate
/// navigation actions.
///
/// This class implements methods that improve and simplify process of delivering
/// business-logic states changes and navigation actions to widgets.
///
/// Current solution contains methods to register states that you want to provide to widgets ([registerState]), send
/// this states ([addState], [addStateSource], [addStatesSource]) and navigation actions ([addNavigation],
/// [addNavigationSource]).
///
/// ```dart
/// class CounterBloc extends Bloc {
///  int value = 0;
///
///  CounterBloc() {
///    registerState<int>(initialState: value);
///  }
///
///  void increment() => addState(++value);
/// }
/// ```
///
/// Widgets should use [getStateStream] and [navigationStream] to subscribe on [Bloc] events.
abstract class Bloc {

  Bloc({bool asyncNavigation = false})
      : _navigationController =
            _StateDeliveryController<RouteData>(sync: !asyncNavigation);

  final _store = _DeliveryControllersStore();
  final _navigationController;
  bool _isDisposed = false;

  /// Registers state of `S` type that can be processed by this [Bloc].
  ///
  /// Creates stream and all necessary resources that need to process state of `S` type.
  /// You can pass object that will define [initialState].
  /// Throws [StateError] if this method was called twice for the same type or if this [Bloc] was closed.
  /// Throws [StateError] if this [Bloc] was disposed.
  @protected
  void registerState<S>({
    S? initialState,
  }) {
    if (isDisposed) {
      throw StateError(
          'This bloc was closed. You can\'t register state for closed bloc');
    }
    _store[S] = _StateDeliveryController<S>(
      initialState: initialState,
    );
  }

  /// Returns initial value for state of `S` type.
  ///
  /// Throws [StateError] if this [Bloc] was disposed.
  /// Throws [ArgumentError] if state of such type was not registered.
  S initialState<S>() => isDisposed
      ? throw StateError('This Bloc was disposed.')
      : _store[S].initialState;

  /// Checks whether a state of `S` type was registered before.
  ///
  /// Throws [StateError] if this [Bloc] was disposed.
  bool containsState<S>() => isDisposed
      ? throw StateError('This Bloc was disposed.')
      : _store.containsKey(S);

  /// Defines whether that [Bloc] was closed.
  bool get isDisposed => _isDisposed;

  /// Adds state of `S` type to the stream that corresponding to state type.
  ///
  /// Throws [StateError] if this [Bloc] was disposed.
  /// Throws [ArgumentError] if state of such type was not registered.
  @protected
  void addState<S>(S? uiState) => isDisposed
      ? throw StateError('You cannot add state to this Bloc, because this Bloc '
          'was disposed.')
      : _store[S].add(uiState);

  /// Adds [Future] that should be returned by state of `S` type as source of state.
  ///
  /// Callbacks [onData], [onDone], [onError] provide possibility to handle [source].
  /// Throws [ArgumentError] if state of such type was not registered.
  /// Throws [StateError] if this [Bloc] was disposed.
  /// Returns [StreamSubscription] that provide possibility to pause, resume or cancel [source].
  @protected
  StreamSubscription<S> addStateSource<S>(Future<S> source,
          {void Function(S data)? onData,
          void Function()? onDone,
          void Function(dynamic error)? onError}) =>
      addStatesSource(source.asStream(),
          onData: onData, onDone: onDone, onError: onError);

  /// Adds states [Stream] of `S` type as source of states.
  ///
  /// Callbacks [onData], [onDone], [onError] help to handle [source].
  /// Throws [ArgumentError] if state of such type was not registered.
  /// Throws [StateError] if this [Bloc] was disposed.
  /// Returns [StreamSubscription] that provide possibility to pause, resume or cancel [source].
  ///
  /// **WARNING!!!** This class doesn't respond for cancellation and closing of [source] stream. Developer should do
  /// it on his own, if necessary.
  @protected
  StreamSubscription<S> addStatesSource<S>(Stream<S> source,
      {void Function(S data)? onData,
      void Function()? onDone,
      void Function(dynamic error)? onError}) {
    return isDisposed
        ? (throw StateError(
            'You cannot add state to this Bloc, because this Bloc '
            'was disposed.'))
        : (_store[S] as _StateDeliveryController<S>).addSource(source,
            onData: onData, onDone: onDone, onError: onError);
  }

  /// Adds navigation data to [navigationStream].
  ///
  /// Method arguments wrap with [RouteData] object and pass to [navigationStream].
  /// Throws [StateError] if this [Bloc] was disposed.
  /// Returns a [Future] that completes to the result value when [RouteData.resultConsumer] function will be called.
  /// [RouteData.resultConsumer] can be called once and only once, otherwise [StateError] will be thrown.
  /// The 'Result' type argument is the type of the return value.
  @protected
  Future<Result> addNavigation<Result>({
    String? routeName,
    dynamic arguments,
  }) {
    if (isDisposed) {
      throw StateError(
          'You cannot use navigation, because this Bloc was disposed.');
    }
    final resultCompleter = Completer<Result>();
    _navigationController.add(RouteData(
      name: routeName,
      arguments: arguments,
      resultConsumer: (Future? result) {
        if (resultCompleter.isCompleted) {
          throw StateError(
              'Navigation result has been already returned. This error has occurred because several Routers try to handle same navigation action. To avoid it try to use precondition functions in your BlocProvider or RouteListener.');
        } else {
          resultCompleter.complete(result?.then((value) {
            try {
              return value as Result;
            } catch (e) {
              throw ArgumentError('Result value type is ${value.runtimeType}, '
                  '$Result expected. Please, check addNavigation() method call.');
            }
          }));
        }
      },
    ));
    return resultCompleter.future;
  }

  /// Adds [Stream] of [RouteData] as navigation events source.
  ///
  /// Callbacks [onData], [onDone], [onError] help to handle [source].
  /// Throws [StateError] if this [Bloc] was disposed.
  /// Returns [StreamSubscription] that provide possibility to pause, resume or cancel [source].
  /// Preferable to use this method for aggregation of blocs.
  /// ```dart
  /// class ConnectionBloc extends Bloc {
  ///
  ///   void startCall(Contact contact) async { ... }
  ///
  ///   void startChat(Contact contact) async { ... }
  /// }
  ///
  /// class ContactsBloc extends Bloc implements ConnectionBloc {
  ///   ContactsBloc(this._connectionBloc) {
  ///      addNavigationSource(_connectionBloc.navigationStream);
  ///   }
  ///
  ///   final ConnectionBloc _connectionBloc;
  ///
  ///   @override
  ///   void startCall(Contact contact) => _connectionBloc.startCall(contact);
  ///
  ///   @override
  ///   void startChat(Contact contact) => _connectionBloc.startChat(contact);
  ///
  ///   ...
  /// }
  /// ```
  @protected
  StreamSubscription<RouteData> addNavigationSource(
    Stream<RouteData> source, {
    void Function(RouteData data)? onData,
    void Function()? onDone,
    void Function(dynamic error)? onError,
  }) {
    return isDisposed
        ? throw StateError(
            'You cannot use navigation, because this Bloc was disposed.')
        : _navigationController.addSource(source,
            onData: onData, onDone: onDone, onError: onError);
  }

  /// Returns states stream according to type `S`.
  ///
  /// Returns `null` if this [Bloc] was closed.
  ///
  /// Throws [ArgumentError] if state of such type was not registered.
  /// Throws [StateError] if this [Bloc] was disposed.
  Stream<S> getStateStream<S>() => isDisposed
      ? throw StateError('Bloc was disposed.')
      : _store[S].stream as Stream<S>;

  /// Returns navigation stream.
  ///
  /// Throws [StateError] if this [Bloc] was disposed.
  /// Returns `null` if this [Bloc] was closed.
  Stream<RouteData> get navigationStream => isDisposed
      ? throw StateError('Bloc was disposed.')
      : _navigationController.stream;

  /// Releases resources and closes streams.
  void dispose() {
    _isDisposed = true;
    _store.forEach((_, holder) => holder.close());
    _store.clear();
    _navigationController.close();
  }
}

/// The class that contains all information about navigation.
class RouteData<T> {
  final String? name;
  final Object? arguments;
  final ResultConsumer<T> resultConsumer;

  RouteData({
    required this.resultConsumer,
    this.name,
    this.arguments,
  });
}

/// Signature of callbacks that use to return navigation result to the [Bloc].
typedef ResultConsumer<T> = void Function(Future<T>?);

class _StateDeliveryController<S> {
  final S? initialState;
  S? _lastState;
  final _subscribers = <MultiStreamController>[];
  final StreamController<S?> _mainController;
  late final Stream<S?> stream;

  _StateDeliveryController({this.initialState, bool sync = false})
      : _mainController = StreamController<S>(sync: sync),
        _lastState = initialState {
    stream = Stream.multi((MultiStreamController<S?> controller) {
      controller.onCancel = () {
        _subscribers.remove(controller);
      };
      if (!_mainController.hasListener) {
        _mainController.stream.listen((event) {
          _lastState = event;
          for (var subscriber in _subscribers) {
            subscriber.addSync(event);
          }
        });
      } else {
        controller.addSync(_lastState);
      }
      _subscribers.add(controller);
    });
  }

  void add(S state) => _mainController.sink.add(state);

  void close() {
    for (var subscriber in _subscribers) {
      subscriber.closeSync();
    }
    _subscribers.clear();
    _mainController.close();
  }

  StreamSubscription<S> addSource(Stream<S> source,
      {void Function(S data)? onData,
      void Function()? onDone,
      void Function(dynamic error)? onError}) {
    return _ImmutableStreamSubscription(source.listen((S data) {
      _mainController.sink.add(data);
      onData?.call(data);
    })
      ..onDone(onDone)
      ..onError(onError));
  }
}

/// A subscription on events from a [Stream] that doesn't allow to replace onData, onDone and onError event handlers.
class _ImmutableStreamSubscription<T> implements StreamSubscription<T> {
  _ImmutableStreamSubscription(this._subscription);

  final StreamSubscription<T> _subscription;

  @override
  Future<E> asFuture<E>([E? futureValue]) =>
      _subscription.asFuture(futureValue);

  @override
  Future cancel() => _subscription.cancel();

  @override
  bool get isPaused => _subscription.isPaused;

  @override
  void onData(void Function(T data)? handleData) {
    throw UnsupportedError(
        'Method onData() doesn\'t supported by this instance of StreamSubscription.');
  }

  @override
  void onDone(void Function()? handleDone) {
    throw UnsupportedError(
        'Method onDone() doesn\'t supported by this instance of StreamSubscription.');
  }

  @override
  void onError(Function? handleError) {
    throw UnsupportedError(
        'Method onError() doesn\'t supported by this instance of StreamSubscription.');
  }

  @override
  void pause([Future? resumeSignal]) {
    _subscription.pause(resumeSignal);
  }

  @override
  void resume() {
    _subscription.resume();
  }
}

class _DeliveryControllersStore extends MapBase<Type, _StateDeliveryController> {
  final _controllersHolder = <Type, _StateDeliveryController>{};

  @override
  _StateDeliveryController operator [](Object? key) {
    return _controllersHolder[key] ??
        (throw ArgumentError('State of $key type was not '
            'found as registered. Please check that you passed correct type to Bloc.addState<T>() method or check that you '
            'called Bloc.registerState<T>() method before.'));
  }

  @override
  void operator []=(Type key, _StateDeliveryController value) {
    _controllersHolder.containsKey(key)
        ? throw ArgumentError(
            'State with type $key already has been registered')
        : _controllersHolder[key] = value;
  }

  @override
  void clear() => _controllersHolder.clear();

  @override
  Iterable<Type> get keys => _controllersHolder.keys;

  @override
  _StateDeliveryController? remove(Object? key) => _controllersHolder.remove(key);
}
