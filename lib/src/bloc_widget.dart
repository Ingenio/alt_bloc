import 'dart:async';
import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'bloc_provider.dart';
import 'precondition.dart';

abstract class BlocSubscriber<B extends Bloc, S> extends StatefulWidget {
  const BlocSubscriber({Key? key, this.precondition}) : super(key: key);

  final Precondition<S>? precondition;
}

abstract class BlocSubscriberState<B extends Bloc, S,
    T extends BlocSubscriber<B, S>> extends State<T> {
  StreamSubscription<S>? _subscription;

  @protected
  Stream<S>? get stream;

  late S currentState;

  Precondition<S>? precondition;

  @protected
  bool dispatchNewState(S state) {
    if (precondition?.call(currentState, state) ?? true) {
      this.currentState = state;
      return true;
    }
    return false;
  }

  @protected
  void onNewState(S state);

  @override
  void initState() {
    _subscribe();
    super.initState();
  }

  void _subscribe() {
    _subscription = stream?.listen((S state) {
      if (dispatchNewState(state)) {
        onNewState(state);
      }
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }
}

abstract class BlocWidget<B extends Bloc, S> extends BlocSubscriber<B, S> {
  const BlocWidget({Key? key, this.bloc, Precondition<S>? precondition})
      : super(key: key, precondition: precondition);

  final B? bloc;
}

abstract class BlocWidgetState<B extends Bloc, S, T extends BlocWidget<B, S>>
    extends BlocSubscriberState<B, S, T> {
  late final B bloc;

  S get initialState => bloc.initialState<S>();

  @override
  void initState() {
    bloc = widget.bloc ?? Provider.of<B>(context);
    currentState = initialState;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    didUpdateBloc(oldWidget.bloc);
  }

  @protected
  void didUpdateBloc(B? oldBloc) {
    final currentBloc = widget.bloc ?? Provider.of<B>(context);
    if (oldBloc != null && oldBloc != currentBloc) {
      bloc = currentBloc;
      onBlocChanged(currentBloc);
    }
  }

  @protected
  void onBlocChanged(B? bloc) {
    _unsubscribe();
    _subscribe();
  }
}
