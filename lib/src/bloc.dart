import 'dart:async';

import 'package:alt_bloc/src/route_state.dart';
import 'package:flutter/foundation.dart';

/// Business Logic Component
abstract class Bloc {
  final _stateHolders = <Type, _StateHolder<dynamic>>{};
  final _navigationController = StreamController<RouteState>();

  bool addNavigation({String routeName, dynamic arguments}) => _navigationController.addIfNotClosed(RouteState
    (name: routeName, args: arguments));

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

  bool addState<US>(US uiState) {
    US state = uiState;
    return _stateHolders[US].controller.addIfNotClosed(state);
  }

  US initialState<US>() {
    return _stateHolders[US].initialState;
  }

  StreamSubscription<US> listenState<US>(void onData(US state)) {
    Stream<US> stream = _stateHolders[US].controller.stream;
    return stream.listen(onData);
  }

  StreamSubscription<RouteState> listenNavigation(void onData(RouteState state)) {
    return _navigationController.stream.listen(onData);
  }
}

class _StateHolder<US> {
  final StreamController<US> controller;

  final US initialState;

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
