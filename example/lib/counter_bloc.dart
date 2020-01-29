import 'package:alt_bloc/alt_bloc.dart';

class CounterBloc extends Bloc {
  final repo = IncrementRepo();

  CounterBloc() {
    registerState<String>(initialState: '');
    registerState<bool>(initialState: false);
  }

  Future<void> increment() async {
    addStreamSource<String>(repo.increment().asStream().map((count) => 'Button was clicked $count times'));
  }
}

class IncrementRepo {
  int _counter = 0;

  Future<int> increment() => Future.delayed(const Duration(seconds: 1), () => ++_counter);

  Future<int> decrement() => Future.delayed(const Duration(seconds: 5), () => --_counter);
}
