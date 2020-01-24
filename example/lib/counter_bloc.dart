
import 'package:alt_bloc/alt_bloc.dart';

class CounterBloc extends Bloc {

  var _counter = 0;

  CounterBloc() {
    registerState<int>(initialState: 10);
    registerState<bool>(initialState: false);
  }

  void increment() {
    addState<bool>(true);
    // delay simulation
    Future.delayed(const Duration(milliseconds: 500), () {
      addState<bool>(false);
      addState<int>(++_counter);
      addNavigation(arguments: _counter);
    });
  }
}
