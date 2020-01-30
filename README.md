# alt_bloc
Library for BLoC design pattern implementation.

## Authors
* Yegor Logachev <yegor.logachev@dashdevs.com> ([DashDevs LLC](https://www.dashdevs.com))
* Olivier Brand <obrand@ingenio.com> ([Ingenio LLC](https://www.ingenio.com))
## Intro 
### Why we decided to create this solution?

We are very excited to present our version of the BLoC pattern. Having implemented Flutter apps since its inception, we have built a strong expertise in the framework and kept up to date on all state management related architecture and packages. Our primary goal is to have a one stop shop for a state management system that is simple enough so anybody can understand and quickly adopt it to build powerful applications. One of our goal was also to avoid relying on complex and 'magical' frameworks such as Rx, or having to use multiple franeworks together to achieve the same outcome **alt_bloc** has to offer.

Existing solutions such as [bloc](https://pub.dev/packages/bloc) and [flutter_bloc](https://pub.dev/packages/flutter_bloc) have limitations in their design. Some of them are: 

* [bloc](https://pub.dev/packages/bloc) library is designed in a way that it can only handle a single state and event class. As a result, developers have to create large hierarchies of classes that inherit, for each bloc, from a base state or event class. As a consequence, the number of events/states classes grows nonlinearly with the number of blocks that leads to an event/state hell. **alt_bloc** does not solve this problem completely, but provides the possibility to reduce the number of states per Bloc and simplify the overall hierarchy of events/states classes.

* [bloc](https://pub.dev/packages/bloc) library makes it very hard to create reusable state in other Bloc classes. For example a simple UX element such as showing a progress indicator would result in lots of Bloc classes containing a state class. Developers would then have to create their own progress state class for each Bloc or build a hierarchy of states in the state class. The first case leads to lots of code duplication, second leads to a very complicated state hierarchy. 

* Finally [bloc](https://pub.dev/packages/bloc) and [flutter_bloc](https://pub.dev/packages/flutter_bloc) libraries contains dependencies on complex libraries and packages such as rxdart and provider. As result this dependencies affects the build time , project size and more importantly increases the complexity and debugging when things do not go as planned.

P.S. We highly respect the authors and developers of [bloc](https://pub.dev/packages/bloc) and [flutter_bloc](https://pub.dev/packages/flutter_bloc) libraries and do not try to somehow descredit them. Our description above is an attempt to objectively describe the current problems of [bloc](https://pub.dev/packages/bloc) and [flutter_bloc](https://pub.dev/packages/flutter_bloc) libraries, and explain the reasons for creating this solution and provide to newcomers to Flutter an easy way to implement BLoC pattern without adding too much complexity.

## Main Features
- Public interfaces of **alt_bloc** are similar to interfaces of popular libraries like **Provider** and **BLoC**. So you do not need to spend lots of time to learn how set up this library.
- Support multi states. You can create few states per **Bloc** and you don't need to create hierarchy of states that inherited from one parent state, especially if such states are on different levels of abstraction.
- Provides separate pipes to handle navigation actions.
- Lightweight solution. The overall package is very small and it doesn't contains any third party libraries.

## Components
#### Bloc
**Bloc** it is a layer that implements the core business logic. Bloc accepts UI actions from the widget and in return notifies the widget's layout about changes in UI state in order to initiate navigation actions.

`abstract class Bloc`

`void addNavigation(String routeName, dynamic arguments)` - notifies **BlocProvider** about new navigation state.

`void registerState<US>({bool isBroadcast = false, US initialState})` - must be called before adding states using **addState**.

  * `isBroadcast` - optional, should be true if you want to listen to current states in many places at the same time. 

  * `initialState` - optional, value of UI state that will be returned by default.

`void addState<US>(US uiState)` - notify all BlocBuilder instances that subscribed to this state about new UI states.

#### BlocProvider
**BlocProvider** is a **StatefulWidget** and is responsible to build the UI (child) part, providing the ability for this child to obtain the **Bloc** and also to enable the **BlocProvider** for receiving navigation events in **Router**.

`class BlocProvider<B extends Bloc> extends StatefulWidget`

`const BlocProvider({Key key, @required B Function() create, @required Widget child, Router router, UpdateShouldNotify<B> shouldNotify})` - constructor that accept:
  * `bloc` - function that implements the **Bloc** creation process.
  * `child` - accept any **Widget**.
  * `router` - optional callback function that will receive navigation states from **Bloc**.
  * `shouldNotify` - optional predicate function that define whether the descendant widgets should be rebuilt in case  **BlocProvider** gets rebuilt.
  
#### Router
`typedef Router = Function(BuildContext context, String name, dynamic args)` - function that is responsible for receiving and handling navigation events.

  
#### Provider
**Provider** is an **InheritedWidget**. **Provider** is responible for obtaining a **Bloc** instance into the widget layout (Dependency injection). **Provider** has a static method **of()**. This method returns **Bloc** from nearest **BlocProvider**.

`class Provider<B extends Bloc> extends InheritedWidget`
`static B of<B extends Bloc>(BuildContext context, {bool listen = false})`
  * `listen` - define whether descendant widgets tree should be rebuilt in case of BlocProvider being rebuilt.

#### BlocBuilder
**BlocBuilder** based on **StatefulWidget** that has builder function with state. **BlocBuilder** automatically finds the **Bloc** with the help of **Provider** and subscribes to **Bloc** updates. The stream for this widget is obtained by state type.
`class BlocBuilder<B extends Bloc, US> extends StatefulWidget`
`const BlocBuilder({B bloc, @required BlocWidgetBuilder<US> builder})`
  * `bloc` - optional parameter, Provider.of() result will be used by default. 
  * `builder` - required function that builds the UI based on the UI state.
  
## Usage

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
    addFutureSource<int>(repo.increment());
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
