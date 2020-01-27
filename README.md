# alt_bloc
Library for BLoC design pattern implementation.

## Authors
* Yegor Logachev <egor@itomy.ch>
[DashDevs](https://www.dashdevs.com)
* Olivier Brand <obrand@ingenio.com>
[Ingenio, LLC](https://www.ingenio.com)
## Intro 
### Why we decided to create this solution?

There are many who can say that we are trying to reinvent the wheel, because there already exists a popular solution that implements Bloc design pattern for Dart and Flutter such as [bloc](https://pub.dev/packages/bloc) and [flutter_bloc](https://pub.dev/packages/flutter_bloc). But existing solution contains some issues in design. Issues that we try to solve are:

* [bloc](https://pub.dev/packages/bloc) library designed so that it can handle only one state class and only one event class. As result sometimes developers should create large hierarchies of classes that are inherited from base state or event for each block. The number of events/states classes grows nonlinearly with the number of blocks that leads to events/states hell. **alt_bloc** does not solve this problem completely, but provide possibility to reduces the number of states per Bloc or simplify hierarchy of events/states classes.

* Very hard to create state that will be reused in other Bloc classes in [bloc](https://pub.dev/packages/bloc) library. For example a lot of Bloc classes contains state class that respond for showing progress indicator. Developer should to create own progress state class for each Bloc or build in this state class to hierarchy of states in this situation. First case leads to code duplication, second leads to complicating hierarchy of states. 

* Third reason more presonal. [bloc](https://pub.dev/packages/bloc) and [flutter_bloc](https://pub.dev/packages/flutter_bloc) libraries contains dependencies on libraries and packages that we don't use in development such as rxdart and provider. As result this dependencies affects the build time and project size.

P.S. We respect the authors and developers of [bloc](https://pub.dev/packages/bloc) and [flutter_bloc](https://pub.dev/packages/flutter_bloc) libraries and do not try to somehow descredit them. All that was described above is an attempt to most objectively describe the current problems of [bloc](https://pub.dev/packages/bloc) and [flutter_bloc](https://pub.dev/packages/flutter_bloc) libraries, and explain the reasons for creating this solution.

## Main Features
- Public interface of **alt_bloc** similar to interface of popular libraries like **Provider** and **BLoC**. So you no need spend a lot of time to learn how set up this library.
- Support multistates. You can create few states per **Bloc** and you don't need create hierarchy of states that inherited from one parent state, especially if this states on different levels of abstraction.
- Contains separate pipe to handle navigation actions.
- Lightweight solution. Package pretty small and it doesn't contains any third party libraries.

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

#### Simple **Bloc** implementation.
You should register all states that will be used by Bloc with help `registerState<T>()` method. To notify **Widget** about changes you should call `addState<T>(T_object);`. 
**WARNING!!!** If you will try to call `addState<T>()` method before `registerState<T>()` error will occured.

If you wanna send some navigation event, you need to call `addNavigation({String routeName, dynamic arguments})` method.

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

#### **BlocProvider**. 
`create` function responsible for Bloc creation.

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
You could handle navigation with help of `router` as it shown in example above. Or you can use **RoutreListener**.

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
