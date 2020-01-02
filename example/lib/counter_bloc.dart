
import 'package:alt_bloc/alt_bloc.dart';

class CounterBloc extends Bloc<int> {

  var _counter = 0;

  CounterBloc() {
    registerState<num>(initialState: 10);
  }

  void increment() {
    addState<num>(++_counter);
    if ((_counter % 10) == 0) {
      addNavigation(_counter);
    }
  }
}