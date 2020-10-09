import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

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
  final _store = _StateHoldersStore();
  final _navigationControllerWrapper = _NavigationStreamControllerWrapper(
      StreamController<RouteData>.broadcast());
  bool _isDisposed = false;

  /// Registers state of `S` type that can be processed by this [Bloc].
  ///
  /// Creates stream and all necessary resources that need to process state of `S` type.
  /// [isBroadcast] define type of stream that will be created.
  /// You can pass object that will define [initialState].
  /// Throws [StateError] if this method was called twice for the same type or if this [Bloc] was closed.
  @protected
  void registerState<S>({bool isBroadcast = false, S initialState}) {
    if (isDisposed) {
      throw StateError(
          'This bloc was closed. You can\'t register state for closed bloc');
    }
    _store[S] = _StateHolder<S>(
        isBroadcast ? StreamController<S>.broadcast() : StreamController<S>(),
        initialState: initialState);
  }

  /// Returns initial value for state of `S` type.
  ///
  /// Returns `null` if this [Bloc] was closed.
  /// Throws [ArgumentError] if state of such type was not registered.
  S initialState<S>() => isDisposed ? null : _store[S].initialState;

  /// Checks whether a state of `S` type was registered before.
  ///
  /// Returns `false` if this [Bloc] was closed.
  bool containsState<S>() => isDisposed ? false : _store.containsKey(S);

  /// Defines whether that [Bloc] was closed.
  bool get isDisposed => _isDisposed;

  /// Adds state of `S` type to the stream that corresponding to state type.
  ///
  /// Returns false if this [Bloc] was closed and state was not added to the stream.
  /// Throws [ArgumentError] if state of such type was not registered.
  @protected
  bool addState<S>(S uiState) {
    if (isDisposed) {
      return false;
    }
    _store[S].controller.sink.add(uiState);
    return true;
  }

  /// Adds [Future] that should be returned by state of `S` type as source of state.
  ///
  /// Callbacks [onData], [onDone], [onError] provide possibility to handle [source].
  /// Throws [ArgumentError] if state of such type was not registered.
  /// Returns [StreamSubscription] that provide possibility to pause, resume or cancel [source].
  @protected
  StreamSubscription<S> addStateSource<S>(Future<S> source,
          {void Function(S data) onData,
          void Function() onDone,
          void Function(dynamic error) onError}) =>
      addStatesSource(source.asStream(),
          onData: onData, onDone: onDone, onError: onError);

  /// Adds states [Stream] of `S` type as source of states.
  ///
  /// Callbacks [onData], [onDone], [onError] help to handle [source].
  /// Throws [ArgumentError] if state of such type was not registered.
  /// Returns [StreamSubscription] that provide possibility to pause, resume or cancel [source].
  ///
  /// **WARNING!!!** This class doesn't respond for cancellation and closing of [source] stream. Developer should do
  /// it on his own, if necessary.
  @protected
  StreamSubscription<S> addStatesSource<S>(Stream<S> source,
      {void Function(S data) onData,
      void Function() onDone,
      void Function(dynamic error) onError}) {
    // ignore: close_sinks
    StreamController<S> controller = isDisposed ? null : _store[S].controller;
    return controller?.addSource(source,
        onData: onData, onDone: onDone, onError: onError);
  }

  /// Adds navigation data to [navigationStream].
  ///
  /// Method arguments wrap with [RouteData] object and pass to [navigationStream].
  /// Returns a [Future] that completes to the result value when [RouteData.resultConsumer] function will be called.
  /// [RouteData.resultConsumer] can be called once and only once, otherwise [StateError] will be thrown.
  /// The 'Result' type argument is the type of the return value.
  @protected
  Future<Result> addNavigation<Result>({String routeName, dynamic arguments}) {
    if (isDisposed) {
      return null;
    }
    final resultCompleter = Completer<Result>();
    _navigationControllerWrapper.add(RouteData(
        RouteSettings(name: routeName, arguments: arguments), (Future result) {
      if (resultCompleter.isCompleted) {
        throw StateError(
            'Navigation result has been already returned. This error has occurred because several Routers try to handle same navigation action. To avoid it try to use precondition functions in your BlocProvider or RouteListener.');
      } else {
        resultCompleter.complete(result.then((value) {
          try {
            return value as Result;
          } catch (e) {
            throw ArgumentError('Result value type is ${value.runtimeType}, '
                '$Result expected. Please, check addNavigation() method call.');
          }
        }));
      }
    }));
    return resultCompleter.future;
  }

  /// Adds [Stream] of [RouteData] as navigation events source.
  ///
  /// Callbacks [onData], [onDone], [onError] help to handle [source].
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
  StreamSubscription<RouteData> addNavigationSource(Stream<RouteData> source,
      {void Function(RouteData data) onData,
      void Function() onDone,
      void Function(dynamic error) onError}) {
    return isDisposed
        ? null
        : _navigationControllerWrapper._streamController.addSource(source,
            onData: onData, onDone: onDone, onError: onError);
  }

  /// Returns states stream according to type `S`.
  ///
  /// Returns `null` if this [Bloc] was closed.
  ///
  /// Throws [ArgumentError] if state of such type was not registered.
  Stream<S> getStateStream<S>() =>
      isDisposed ? null : _store[S].controller.stream;

  /// Returns navigation stream.
  ///
  /// Returns `null` if this [Bloc] was closed.
  Stream<RouteData> get navigationStream =>
      isDisposed ? null : _navigationControllerWrapper.stream;

  /// Releases resources and closes streams.
  void dispose() {
    _isDisposed = true;
    _store.forEach((_, holder) => holder.controller.close());
    _store.clear();
    _navigationControllerWrapper.close();
  }
}

/// The class that contains all information about navigation.
class RouteData<T> {
  final RouteSettings settings;
  final ResultConsumer<T> resultConsumer;

  RouteData(this.settings, this.resultConsumer);
}

/// Signature of callbacks that use to return navigation result to the [Bloc].
typedef ResultConsumer<T> = void Function(Future<T>);

class _StateHolder<S> {
  final StreamController<S> controller;

  final S initialState;

  _StateHolder(this.controller, {this.initialState});
}

extension _BlocStreamController<T> on StreamController<T> {
  /// This function returns _ImmutableStreamSubscription to avoid that onData or onError handlers will be replaced.
  StreamSubscription<T> addSource(Stream<T> source,
      {void Function(T data) onData,
      void Function() onDone,
      void Function(dynamic error) onError}) {
    return _ImmutableStreamSubscription(source.listen((T data) {
      sink.add(data);
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
  Future<E> asFuture<E>([E futureValue]) => _subscription.asFuture(futureValue);

  @override
  Future cancel() => _subscription.cancel();

  @override
  bool get isPaused => _subscription.isPaused;

  @override
  void onData(void Function(T data) handleData) {
    throw UnsupportedError(
        'Method onData() doesn\'t supported by this instance of StreamSubscription.');
  }

  @override
  void onDone(void Function() handleDone) {
    throw UnsupportedError(
        'Method onDone() doesn\'t supported by this instance of StreamSubscription.');
  }

  @override
  void onError(Function handleError) {
    throw UnsupportedError(
        'Method onError() doesn\'t supported by this instance of StreamSubscription.');
  }

  @override
  void pause([Future resumeSignal]) {
    _subscription.pause(resumeSignal);
  }

  @override
  void resume() {
    _subscription.resume();
  }
}

class _NavigationStreamControllerWrapper<T> {
  _NavigationStreamControllerWrapper(this._streamController) {
    _streamController.onListen = () {
      if (_lastEvent != null) {
        add(_lastEvent);
        _lastEvent = null;
      }
    };
  }

  final StreamController<T> _streamController;

  T _lastEvent;

  bool add(T event) {
    if (_streamController.hasListener) {
      if (!_streamController.isClosed) {
        _streamController.sink.add(event);
        return true;
      }
    } else {
      _lastEvent = event;
    }
    return false;
  }

  void close() {
    _streamController.close();
  }

  Stream<T> get stream => _streamController.stream;
}

class _StateHoldersStore extends MapBase<Type, _StateHolder<dynamic>> {
  final _stateHolders = <Type, _StateHolder<dynamic>>{};

  @override
  _StateHolder operator [](Object key) {
    return _stateHolders[key] ??
        (throw ArgumentError('State of $key type was not '
            'found as registered. Please check that you passed correct type to Bloc.addState<T>() method or check that you '
            'called Bloc.registerState<T>() method before.'));
  }

  @override
  void operator []=(Type key, _StateHolder value) {
    _stateHolders.containsKey(key)
        ? throw ArgumentError(
            'State with type $key already has been registered')
        : _stateHolders[key] = value;
  }

  @override
  void clear() => _stateHolders.clear();

  @override
  Iterable<Type> get keys => _stateHolders.keys;

  @override
  _StateHolder remove(Object key) => _stateHolders.remove(key);
}
