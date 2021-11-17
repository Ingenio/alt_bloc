import 'package:alt_bloc/alt_bloc.dart';
import 'package:flutter/material.dart';

import 'counter_bloc.dart';

class CounterLayout extends StatelessWidget {
  CounterLayout({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Stack(
        children: <Widget>[
          Center(
            child: BlocBuilder<CounterBloc, bool?>(
              builder: (_, inProgress) => inProgress ?? false
                  ? CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'You have pushed the button this many times:',
                        ),
                        BlocBuilder<CounterBloc, int?>(
                          builder: (_, count) {
                            return Text(
                              '$count',
                              style: Theme.of(context).textTheme.headline4,
                            );
                          },
                        ),
                        BlocBuilder<CounterBloc, int?>(
                          builder: (_, count) {
                            return Text(
                              '$count',
                              style: Theme.of(context).textTheme.headline5,
                            );
                          },
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: Provider.of<CounterBloc>(context).increment,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
