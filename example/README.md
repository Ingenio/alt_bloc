## Example

```dart
void main() => runApp(CounterApp());

class CounterApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CounterScreen()
    );
  }
}
```

#### Simple **Bloc** implementation.
You should register all states that will be used by Bloc with the help of the `registerState<T>()` method. To notify **Widget** about changes you should call `addState<T>(T_object);`. 
**WARNING!!!** If you try to call `addState<T>()` method before `registerState<T>()` an error will be thrown.

If you want to send some navigation events, you need to call `addNavigation({String routeName, dynamic arguments})` method.

```dart
class CounterBloc extends Bloc {

  var _counter = 0;

  CounterBloc() {
    registerState<int>(initialState: 10);
    registerState<bool>(initialState: false);
  }

  void increment() {
    addState<bool>(true);
    Future.delayed(const Duration(milliseconds: 500), () {
      addState<bool>(false);
      addState<int>(++_counter);
      if ((_counter % 10) == 0) {
        addNavigation(arguments: _counter);
      }
    });
  }
}
```

If you have some Future or Stream that contains state objects you can pass it as state source 
with help `addStreamSource<S>(Stream<S> source)` and `addFutureSource<S>(Future<S> source)` 
functions.
For example we have some repository that return Future with incrementation result.

```dart
class IncrementRepo {
  int _counter = 0;

  Future<int> increment() => Future.delayed(const Duration(seconds: 1), () => ++_counter);

  Future<int> decrement() => Future.delayed(const Duration(seconds: 5), () => --_counter);
} 

class CounterBloc extends Bloc {
  final repo = IncrementRepo();

  CounterBloc() {
    registerState<int>(initialState: 0);
    registerState<bool>(initialState: false);
  }

  void increment() {
      addState<bool>(true);
      addFutureSource<int>(repo.increment(),
          onData: (count) async {
            print('Dialog result: ${await addNavigation(arguments: count)}');
          },
          onDone: () => addState<bool>(false));
    }
}
```

#### **BlocProvider**. 
`create` function responsible for the Bloc creation.

```dart
class CounterScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CounterBloc>(
      create: () => CounterBloc(),
      routerPrecondition: (_, routeData) => (routeData.settings.arguments as int) % 5 == 0,
      child: CounterLayout(title: 'Bloc Demo Home Page'),
      router: (context, name, args) {
        return showDialog(
          context: context,
          builder: (_) => WillPopScope(
                          child: AlertDialog(
                            title: Text('Congratulations! You clicked $args times'),
                          ),
                          onWillPop: () async {
                            Navigator.of(context).pop(args);
                            return false;
                          })
        );
      },
    );
  }
}
```

#### Navigation handling.
You could handle navigation with the help of `router` as shown in the example above. Or you can use **RoutreListener**.

```dart
class CounterScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CounterBloc>(
      create: () => CounterBloc(),
      child: RouteListener<CounterBloc>(
        child: CounterLayout(title: 'Bloc Demo Home Page'),
        router: (context, name, args) {
          return showDialog(
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
```

#### Providing and observing **Bloc** on UI.

```dart
class CounterLayout extends StatelessWidget {

  CounterLayout({Key key, this.title}) : super(key: key);

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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'You have pushed the button this many times:',
                ),
                BlocBuilder<CounterBloc, int>(
                    builder: (_, count) {
                      return Text(
                        '$count',
                        style: Theme.of(context).textTheme.display1,
                      );
                    }),
              ],
            ),
          ),
          Center(
            child: BlocBuilder<CounterBloc, bool>(
              builder: (_, inProgress) {
                return inProgress ? CircularProgressIndicator() : Container();
              }
            ),
          )
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
```
