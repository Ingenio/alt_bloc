import 'package:alt_bloc/alt_bloc.dart';

class CounterBloc extends Bloc {
  final repo = IncrementRepo();

  CounterBloc() {
    registerState<int>(initialState: 0);
    registerState<bool>(initialState: false);
  }

  void increment() {
    addState<bool>(true);
    addStateSource<int>(repo.increment(),
        onData: (count) async {
          print(await addNavigation<String>(arguments: count));
        },
        onDone: () => addState<bool>(false));
  }
}

class IncrementRepo {
  int _counter = 0;

  Future<int> increment() =>
      Future.delayed(const Duration(seconds: 1), () => ++_counter);

  Future<int> decrement() =>
      Future.delayed(const Duration(seconds: 5), () => --_counter);
}
