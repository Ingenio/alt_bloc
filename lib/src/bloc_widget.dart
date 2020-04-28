import 'dart:async';

import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'bloc_provider.dart';
import 'precondition.dart';

abstract class BlocSubscriber<B extends Bloc, S> extends StatefulWidget {
  const BlocSubscriber({Key key, this.precondition}) : super(key: key);

  final Precondition<S> precondition;
}

abstract class BlocSubscriberState<B extends Bloc, S,
    T extends BlocSubscriber<B, S>> extends State<T> {
  StreamSubscription<S> _subscription;
  S currentState;
  S previousState;

  @protected
  Stream<S> get stream;

  @protected
  S get initialState => null;

  @override
  void initState() {
    currentState = initialState;
    _subscribe();
    super.initState();
  }

  void _subscribe() {
    _subscription = stream?.listen((S state) {
      if (widget.precondition?.call(previousState, state) ?? true) {
        previousState = this.currentState;
        this.currentState = state;
        onNewState(state);
      }
    });
  }

  @protected
  void onNewState(S state);

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
  const BlocWidget({Key key, this.bloc, Precondition<S> precondition})
      : super(key: key, precondition: precondition);

  final B bloc;
}

abstract class BlocWidgetState<B extends Bloc, S, T extends BlocWidget<B, S>>
    extends BlocSubscriberState<B, S, T> {
  B bloc;

  @override
  void initState() {
    bloc = widget.bloc ?? Provider.of<B>(context);
    super.initState();
  }

  @override
  void didUpdateWidget(BlocWidget<B, S> oldWidget) {
    didUpdateBloc(oldWidget.bloc);
    super.didUpdateWidget(oldWidget);
  }

  @protected
  void didUpdateBloc(B oldBloc) {
    final currentBloc = widget.bloc ?? Provider.of(context);
    if (oldBloc != null && oldBloc != currentBloc) {
      bloc = currentBloc;
      onBlocChanged(currentBloc);
    }
  }

  @protected
  void onBlocChanged(B bloc) {
    _unsubscribe();
    _subscribe();
  }
}
