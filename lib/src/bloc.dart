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

}
