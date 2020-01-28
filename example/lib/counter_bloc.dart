
import 'package:alt_bloc/alt_bloc.dart';

class CounterBloc extends Bloc {

//  var _counter = 0;

  final repo = IncrementRepo();

  CounterBloc() {
    registerState<int>(initialState: 10);
    registerState<bool>(initialState: false);
  }

  Future<void> increment() async {
    mapStreamOnState<int>(repo.increment().asStream());
    mapStreamOnState<int>(repo.decrement().asStream());



//    addState<bool>(true);
//    // delay simulation
//    Future.delayed(const Duration(milliseconds: 500), () {
//      addState<bool>(false);
//      addState<int>(++_counter);
//      addNavigation(arguments: _counter);
//    });
  }
}

class IncrementRepo {

  int _counter = 0;

  Future<int> increment() => Future.delayed(const Duration(milliseconds: 500), () => ++_counter);

  Future<int> decrement() => Future.delayed(const Duration(milliseconds: 700), () => --_counter);

}
