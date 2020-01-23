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
      router: (context, name, args) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Congratulations! You clicked $args times'),
          ),
        );
      },
      child: RouteListener<CounterBloc>(
        child: CounterLayout(title: 'Bloc Demo Home Page'),
        router: (context, name, args) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('Congratulations! You clicked $args times'),
            ),
          );
        },
      ),
    );
  }
}
