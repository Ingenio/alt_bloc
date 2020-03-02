import 'dart:async';

import 'package:flutter/widgets.dart';

/// Business Logic Component
abstract class Bloc {
  final _stateHolders = <Type, _StateHolder<dynamic>>{};
  final _navigationController = StreamController<RouteData>.broadcast();

  @protected
  Future<Result> addNavigation<Result>({String routeName, dynamic arguments}) {
    final resultCompleter = Completer<Result>();
    _navigationController.addIfNotClosed(
        RouteData<Result>(RouteSettings(name: routeName, arguments: arguments),
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
    _stateHolders.forEach((_, holder) => holder.controller.close());
    _stateHolders.clear();
    _navigationController.close();
  }

  @protected
  void registerState<S>({bool isBroadcast = false, S initialState}) {
    if (_stateHolders.containsKey(S)) {
      throw ArgumentError('State with type $S already has been registered');
    } else {
      final stateHolder = _StateHolder<S>(
          isBroadcast ? StreamController<S>.broadcast() : StreamController<S>(),
          initialState: initialState);
      _stateHolders[S] = stateHolder;
    }
  }

  @protected
  bool addState<S>(S uiState) {
    S state = uiState;
    return _checkAndGetStateHolder(S).controller.addIfNotClosed(state);
  }

  @protected
  S initialState<S>() {
    return _checkAndGetStateHolder(S).initialState;
  }

  StreamSubscription<S> listenState<S>(void onData(S state)) {
    Stream<S> stream = _checkAndGetStateHolder(S).controller.stream;
    return stream.listen(onData);
  }

  StreamSubscription<RouteData> listenNavigation(void onData(RouteData state)) {
    return _navigationController.stream.asBroadcastStream().listen(onData);
  }

  @protected
  StreamSubscription<S> addStreamSource<S>(Stream<S> source,
      {void Function(S data) onData,
      void Function() onDone,
      void Function(dynamic error) onError}) {
    // ignore: close_sinks
    StreamController<S> controller = _checkAndGetStateHolder(S).controller;
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

  _StateHolder _checkAndGetStateHolder(Type type) {
    return _stateHolders.containsKey(type)
        ? _stateHolders[type]
        : throw ArgumentError('State of $type type was not '
            'found as registered. Please check that you passed correct type to addState<T>() method or check that you '
            'called registerState<T>() method before.');
  }
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
  bool addIfNotClosed(T event) {
    if (!isClosed) {
      sink.add(event);
      return true;
    }
    return false;
  }

  /// This function returns _ImmutableStreamSubscription to avoid that onData or onError handlers will be replaced.
  StreamSubscription<T> addSource(Stream<T> source,
      {void Function(T data) onData,
      void Function() onDone,
      void Function(dynamic error) onError}) {
    return _ImmutableStreamSubscription(source.listen((T data) {
      if (addIfNotClosed(data)) {
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
