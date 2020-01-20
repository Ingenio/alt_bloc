
import 'package:alt_bloc/alt_bloc.dart';

class CounterBloc extends Bloc {

  var _counter = 0;

  CounterBloc() {
    registerState<num>(initialState: 10);
    registerState<bool>(initialState: false);
  }

  void increment() {
    addState<bool>(true);
    // delay simulation
    Future.delayed(const Duration(milliseconds: 500), () {
      addState<bool>(false);
      addState<num>(++_counter);
      if ((_counter % 10) == 0) {
        addNavigation(arguments: _counter);
      }
    });
  }
}