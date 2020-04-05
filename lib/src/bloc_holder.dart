import 'package:flutter/widgets.dart';

import 'bloc.dart';
import 'bloc_provider.dart';

abstract class BlocHolder<B extends Bloc> extends StatefulWidget {
  const BlocHolder({Key key, this.bloc}) : super(key: key);

  final B bloc;
}

abstract class BlocHolderState<B extends Bloc, T extends BlocHolder<B>>
    extends State<T> {
  B bloc;

  @override
  void initState() {
    super.initState();
    bloc = widget.bloc ?? Provider.of<B>(context);
  }

  @override
  void didUpdateWidget(BlocHolder<B> oldWidget) {
    super.didUpdateWidget(oldWidget);
    didUpdateBloc(oldWidget.bloc);
  }

  void didUpdateBloc(B oldBloc) {
    final currentBloc = widget.bloc ?? Provider.of(context);
    if (oldBloc != null && oldBloc != currentBloc) {
      bloc = currentBloc;
      onBlocChanged(currentBloc);
    }
  }

  void onBlocChanged(B bloc) {}
}
