import 'dart:async';


import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// Business Logic Component
abstract class Bloc {

  final _stateHolders = <Type, _StateHolder<dynamic>>{};
  final _navigationController = StreamController<RouteSettings>.broadcast();

  bool addNavigation({String routeName, dynamic arguments}) {
    return _navigationController.addIfNotClosed(RouteSettings(name: routeName, arguments: arguments));
  }


  void dispose() {
    _stateHolders.forEach((_, holder) => holder.controller.close());
    _stateHolders.clear();
    _navigationController.close();
  }

  void registerState<S>({bool isBroadcast = false, S initialState}) {
    if (_stateHolders.containsKey(S)) {
      throw FlutterError('State with type $S already has been registered');
    } else {
      final stateHolder = _StateHolder<S>(isBroadcast ? StreamController<S>.broadcast() : StreamController<S>(),
          initialState: initialState);
      _stateHolders[S] = stateHolder;
    }
  }

  bool addState<S>(S uiState) {
    S state = uiState;
    return _stateHolders[S].controller.addIfNotClosed(state);
  }

  S initialState<S>() {
    return _stateHolders[S].initialState;
  }

  StreamSubscription<S> listenState<S>(void onData(S state)) {
    Stream<S> stream = _stateHolders[S].controller.stream;
    return stream.listen(onData);
  }

  StreamSubscription<RouteSettings> listenNavigation(void onData(RouteSettings state)) {
    return _navigationController.stream.asBroadcastStream().listen(onData);
  }

  StreamSubscription<S> addStreamSource<S>(Stream<S> source) {
    // ignore: close_sinks
    StreamController<S> controller = _stateHolders[S].controller;
    return controller.addSource(source);
  }

  StreamSubscription<S> addFutureSource<S>(Future<S> source) => addStreamSource(source.asStream());
}

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
  StreamSubscription<T> addSource(Stream<T> source) {
    return _ImmutableStreamSubscription(source.listen((T data) {
      addIfNotClosed(data);
    })
      ..onError((error) {
        if (!isClosed) {
          sink.addError(error);
        }
      }));
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
    throw UnsupportedError('Method onData() doesn\'t supported for this instance of StreamSubscription.');
  }

  @override
  void onDone(void Function() handleDone) {
    throw UnsupportedError('Method onDone() doesn\'t supported for this instance of StreamSubscription.');
  }

  @override
  void onError(Function handleError) {
    throw UnsupportedError('Method onError() doesn\'t supported for this instance of StreamSubscription.');
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
