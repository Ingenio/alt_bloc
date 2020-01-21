# alt_bloc
Library for BLoC design pattern implementation. Inspired by [BLoC](https://pub.dev/packages/bloc), [Provider](https://pub.dev/packages/provider) libraries and my own experience of Flutter development.

## Main Features
- Public interface of **alt_bloc** similar to interface of popular libraries like **Provider** and **BLoC**. So you no need spend a lot of time to learn how set up this library.
- Support multistates. You can create few states per **Bloc** and you don't need create hierarchy of states that inherited from one parent state, especially if this states on different levels of abstraction.
- Contains separate pipe to handle navigation actions.
- Lightweight solution. Package pretty small (near 250 lines of code, but can little bit grow in future) and it doesn't contains any third party libraries.

## Components
#### Bloc
**Bloc** it is an layer that implements business logic. Bloc accept actions from UI and could notify layout widget about changes in UI state and could initiate navigation actions.

`abstract class Bloc`

`void addNavigation(String routeName, dynamic arguments)` - notify **BlocProvider** about new navigation state.

`void registerState<US>({bool isBroadcast = false, US initialState})` - previously than notify UI about changes, developer should register UI state class.

  * `isBroadcast` - optional, should be true if you wanna listen current state more than one place in the same time. 

  * `initialState` - optional, value of UI state that will be returned by default.

`void addState<US>(US uiState)` - notify all BlocBuilder instances that subscribed on this state about new UI state.

#### BlocProvider
**BlocProvider** is **StatefulWidget** and it responsible to build UI (child) part, provide ability for this child to obtain **Bloc** and also **BlocProvider** will receive navigation events in **Router**.

`class BlocProvider<B extends Bloc> extends StatefulWidget`

`const BlocProvider({Key key, @required B Function() create, @required Widget child, Router router, UpdateShouldNotify<B> shouldNotify})` - constructor that accept:
  * `bloc` - function that implement process of **Bloc** creation.
  * `child` - accept any **Widget**.
  * `router` - optional callback function that will receive navigation states from **Bloc**.
  * `shouldNotify` - optional predicate function that define whether the descendant widgets should be rebuilt in case if **BlocProvider** was rebuilt.
  
#### Router
`typedef Router = Function(BuildContext context, String name, dynamic args)` - function that responsible for receiving and handling navigation events.

  
#### Provider
**Provider** is an **InheritedWidget**. **Provider** is designed for obtain **Bloc** instance into layout widget (Dependency injection). **Provider** has static method **of()**. This method returns **Bloc** from nearest **BlocProvider**.

`class Provider<B extends Bloc> extends InheritedWidget`
`static B of<B extends Bloc>(BuildContext context, {bool listen = false})`
  * `listen` - define whether descendant widgets tree should be rebuilt in case if BlocProvider will be rebuilt.

#### BlocBuilder
**BlocBuilder** based on **StatefulWidget** that has builder function with state. **BlocBuilder** automatically finds **Bloc** with help of **Provider** and subscribe on updates of **Bloc**. Stream for this widget is obtained by state type.
`class BlocBuilder<B extends Bloc, US> extends StatefulWidget`
`const BlocBuilder({B bloc, @required BlocWidgetBuilder<US> builder})`
  * `bloc` - optional param, Provider.of() result will be used by default. 
  * `builder` - required function that build UI based on UI state.
  
## Usage
Simple **Bloc** implementation. To notify **Widget** about changes you should call `addState<T>(T_object);`. If you wanna do some navigation you need to call `addNavigation({String routeName, dynamic arguments})` method.

```dart
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
      if ((_counter % 10) == 0) {
        addNavigation(arguments: _counter);
      }
    });
  }
}
```

**Bloc** creation and navigation handling. `create` function responsible for Bloc creation, `router` - for handling navigation.

```dart
class CounterScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CounterBloc>(
      create: () => CounterBloc(),
      child: CounterLayout(title: 'Bloc Demo Home Page'),
      router: (context, name, args) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Congratulations! You clicked $args times'),
          ),
        );
      },
    );
  }
}
```

Providing and observing **Bloc** on UI.

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
