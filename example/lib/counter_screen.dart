import 'package:alt_bloc/alt_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'counter_bloc.dart';
import 'counter_layout.dart';

/// entity that encapsulate mapping Layout(UI), Bloc(Business Logic), router(Navigation Handler) on BlocProvider
class CounterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<CounterBloc>(
      create: () => CounterBloc(),
      child: RouteListener<CounterBloc>(
        child: CounterLayout(title: 'Bloc Demo Home Page'),
        precondition: (prevData, data) =>
            (data.settings.arguments as int) % 5 == 0,
        router: (context, name, args) {
          return showDialog(
              context: context,
              builder: (_) => WillPopScope(
                  child: AlertDialog(
                    title: Text('Congratulations! You clicked $args times'),
                  ),
                  onWillPop: () async {
                    Navigator.of(context)
                        .pop('Dialog with $args clicks has been closed');
                    return false;
                  }));
        },
      ),
    );
  }
}
