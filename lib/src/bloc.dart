import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

/// Business Logic Component
abstract class Bloc {
  final _store = _StateHoldersStore();
  final _navigationControllerWrapper = _NavigationStreamControllerWrapper(
      StreamController<RouteData>.broadcast());

  @protected
  Future<Result> addNavigation<Result>({String routeName, dynamic arguments}) {
    final resultCompleter = Completer<Result>();
    _navigationControllerWrapper.add(
        RouteData<Result>(
            RouteSettings(name: routeName, arguments: arguments),
                (Future<Result> result) {
              if (resultCompleter.isCompleted) {
                throw StateError(
                    'Navigation result has been already returned. This error has occurred because several Routers try to handle same navigation action. To avoid it try to use precondition functions in your BlocProvider or RouteListener.');
              } else {
                resultCompleter.complete(result);
              }
            }));
    return resultCompleter.future;
  }

  void dispose() {
    _store.forEach((_, holder) => holder.controller.close());
    _navigationControllerWrapper.close();
  }

  @protected
  void registerState<S>({bool isBroadcast = false, S initialState}) {
    _store[S] = _StateHolder<S>(
        isBroadcast ? StreamController<S>.broadcast() : StreamController<S>(),
        initialState: initialState);
  }

  @protected
  bool addState<S>(S uiState) {
    // ignore: close_sinks
    final controller = _store[S].controller;
    if (!controller.isClosed) {
      controller.sink.add(uiState);
      return true;
    }
    return false;
  }

  bool containsState<S>() => _store.containsKey(S);

  S initialState<S>() => _store[S].initialState;

  Stream<RouteData> get navigationStream => _navigationControllerWrapper.stream;

  Stream<S> getStateStream<S>() => _store[S].controller.stream;

  @protected
  StreamSubscription<S> addStreamSource<S>(Stream<S> source,
      {void Function(S data) onData,
      void Function() onDone,
      void Function(dynamic error) onError}) {
    // ignore: close_sinks
    StreamController<S> controller = _store[S].controller;
    return controller.addSource(source,
        onData: onData, onDone: onDone, onError: onError);
  }

  @protected
  StreamSubscription<S> addFutureSource<S>(Future<S> source,
          {void Function(S data) onData,
          void Function() onDone,
          void Function(dynamic error) onError}) =>
      addStreamSource(source.asStream(),
          onData: onData, onDone: onDone, onError: onError);

}

class RouteData<T> {
  final RouteSettings settings;
  final ResultConsumer<T> resultConsumer;

  RouteData(this.settings, this.resultConsumer);
}

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
      if (!isClosed) {
        sink.add(data);
        onData?.call(data);
      }
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
    return _stateHolders[key] ?? (throw ArgumentError('State of $key type was not '
        'found as registered. Please check that you passed correct type to Bloc.addState<T>() method or check that you '
        'called Bloc.registerState<T>() method before.'));
  }

  @override
  void operator []=(Type key, _StateHolder value) {
    _stateHolders.containsKey(key)
        ? throw ArgumentError('State with type $key already has been registered')
        : _stateHolders[key] = value;
  }

  @override
  void clear() => _stateHolders.clear();

  @override
  Iterable<Type> get keys => _stateHolders.keys;

  @override
  _StateHolder remove(Object key) => _stateHolders.remove(key);

}
