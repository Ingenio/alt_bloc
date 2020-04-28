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
- Support `Stream` and `Future` objects as states provider.
- Provides separate pipes to handle navigation actions.
- Contains solution to receive result of navigation in the Bloc object.
- Lightweight solution. The overall package is very small and it doesn't contains any third party libraries.

## Components
#### Bloc

Business Logic Component.

The class that implements the core business logic, and that should be placed between UI and data source. BLoC accepts UI actions from the widget and in return notifies the widget's about changes in UI state or initiate navigation actions.

This class implements methods that improve and simplify process of delivering business-logic states changes and navigation actions to widgets.

Current solution contains methods to register states that you want to provide to widgets (`registerState()`), send this states (`addState()`, `addStateSource()`, `addStatesSource()`) and navigation actions (`addNavigation()`, `addNavigationSource()`).

```dart
class CounterBloc extends Bloc {
 int value = 0;

 CounterBloc() {
   registerState<int>(initialState: value);
 }

 void increment() => addState(++value);
}
```

Widgets should use `getStateStream()` and `navigationStream` property to subscribe on `Bloc` events.

`abstract class Bloc`

`void registerState<S>({bool isBroadcast = false, S initialState})` - registers state of `S` type
 that can be processed by this `Bloc`.Creates stream and all necessary resources that need to process state of `S` type. `isBroadcast` define type of stream that will be created. You can pass object that will define `initialState`. Throws `StateError` if this method was called twice for the same type or if this `Bloc` was closed.
 
`S initialState<S>()` - returns initial value for state of `S` type. Returns `null` if this `Bloc` was closed. Throws `ArgumentError` if state of such type was not registered.

`bool containsState<S>()` - checks whether a state of `S` type was registered before. Returns `false` if this `Bloc` was closed.

`isClosed` - Defines whether that `Bloc` was closed.

`bool addState<S>(S uiState)` - adds state of `S` type to the stream that corresponding to state type. Returns false if this `Bloc` was closed and state was not added to the stream. Throws `ArgumentError` if state of such type was not registered.

`StreamSubscription<S> addStateSource<S>(Future<S> source,
           {void Function(S data) onData,
           void Function() onDone,
           void Function(dynamic error) onError})` - adds `Future` that should be returned by state of `S` type as source of state. Callbacks `onData`, `onDone`, `onError` provide possibility to handle `source`. Throws `ArgumentError` if state of such type was not registered. Returns `StreamSubscription` that provide possibility to pause, resume or cancel `source`.
           
`StreamSubscription<S> addStatesSource<S>(Stream<S> source,
       {void Function(S data) onData,
       void Function() onDone,
       void Function(dynamic error) onError})` - adds `Stream` that should be returned by state of `S` type as source of state. Callbacks `onData`, `onDone`, `onError` provide possibility to handle `source`. Throws `ArgumentError` if state of such type was not registered. Returns `StreamSubscription` that provide possibility to pause, resume or cancel `source`.           
           
`Future<Result> addNavigation<Result>({String routeName, dynamic arguments})` - adds navigation data to `navigationStream`. Method arguments wrap with `RouteData` object and pass to `navigationStream`. Returns a `Future` that completes to the result value when `RouteData.resultConsumer` function will be called. `RouteData.resultConsumer` can be called once and only once, otherwise `StateError` will be thrown. The 'Result' type argument is the type of the return value.

`StreamSubscription<RouteData> addNavigationSource(Stream<RouteData> source,
      {void Function(RouteData data) onData,
        void Function() onDone,
        void Function(dynamic error) onError})` - adds `Stream` of `RouteData` as navigation events source. Callbacks `onData`, `onDone`, `onError` help to handle `source`. Returns `StreamSubscription` that provide possibility to pause, resume or cancel `source`. Preferable to use this method for aggregation of blocs.
 ```dart
 class ConnectionBloc extends Bloc {
  
   void startCall(Contact contact) async { ... }
  
   void startChat(Contact contact) async { ... }
 }
  
 class ContactsBloc extends Bloc implements ConnectionBloc {
   ContactsBloc(this._connectionBloc) {
      addNavigationSource(_connectionBloc.navigationStream);
   }
 
   final ConnectionBloc _connectionBloc;
 
   @override
   void startCall(Contact contact) => _connectionBloc.startCall(contact);
 
   @override
   void startChat(Contact contact) => _connectionBloc.startChat(contact);
 
   ...
 }
 ```

`Stream<S> getStateStream<S>()` - returns states stream according to type `S`. Returns `null` if this `Bloc` was closed. Throws `ArgumentError` if state of such type was not registered.

`navigationStream` - returns navigation stream. Returns `null` if this `Bloc` was closed.

`void close()` - Releases resources and closes streams.


#### RouteData 
The class that contains all information about navigation.


#### ResultConsumer
Signature of callback that use to return navigation result to the `Bloc`.


#### BlocProvider
`Widget` that responsible to create the `Bloc` with help of `create` function. Accepts any `Widget` as child and provides the ability for child to obtain the `Bloc`.
Function `shouldNotify` define whether that widgets that inherit from this widget should be rebuilt if `Bloc` was changed.
`BlocProvider` could subscribe on `Bloc.navigationStream` and receives navigation events if `router` function will be defined, similar as `RouteListener`.

```dart
class CounterScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CounterBloc>(
      routerPrecondition: (prevRouteData, routeData) => (routeData.settings.arguments as int) % 5 == 0,
      create: () => CounterBloc(),
      child: CounterLayout(title: 'Bloc Demo Home Page'),
      router: (context, name, args) {
        return showDialog(
            context: context,
            builder: (_) {
              return WillPopScope(
                  child: AlertDialog(
                    title: Text('Congratulations! You clicked $args times'),
                  ),
                  onWillPop: () async {
                    Navigator.of(context).pop('Dialog with $args clicks has been closed');
                    return false;
                  }
              );
            }
        );
      },
    );
  }
}
```


#### Provider
`InheritedWidget` that encapsulated by `BlocProvider` and allow `BlocProvider.child` widgets tree to obtain the `Bloc` object.
`static B of<B extends Bloc>(BuildContext context, {bool listen = false})` - static function that returns `Bloc` of type `B`. If `listen` defines as `true`, each time when `Bloc` object changes, this `context` is rebuilt. Custom `Bloc` comparison rules could be defined in `BlocProvider.shouldNotify` function.


#### BlocBuilder
`Widget` that accept `Bloc` of type `B` and subscribes on states stream of type `S`. If `Bloc
` was not provided, so `Provider.of` uses by default. 
Function `builder` calls each time when new state was added to stream and returns `Widget` depending on state. `precondition` allow to filter stats that will be delivered to `builder`.

```dart
BlocBuilder<CounterBloc, int>(
    bloc: CounterBloc(),
    precondition: (prevCount, count) => count % 2 == 0,
    builder: (_, count) => Text('$count');
)
```

#### BlocConsumer
`Widget` that accept `Bloc` of type `B` and subscribes on states stream of type `S`. If `Bloc` was not provided, so `Provider.of` uses by default.
`consumer` function will be triggered each time on new state.

  
#### RouteListener
`Widget` that subscribes on `Bloc.navigationStream`, listen for navigation actions and handle them. If `bloc` was not provided `Provider.of` will be used by default. 
`router` function will be triggered each time on new state and returns navigation result to the
 `Bloc`.

**WARNING!!!** Potentially few `RouteListener` widgets could be subscribed on the same stream, so same navigation event could be handled several times. We recommend to use `precondition` to avoid such situation.

```dart
RouteListener<CounterBloc>(
  bloc: CounterBloc(),
  child: CounterLayout(title: 'Bloc Demo Home Page'),
  precondition: (prevData, data) => (data.settings.arguments as int) % 5 == 0,
  router: (context, name, args) {
    return showDialog(
        context: context,
        builder: (_) {
          return WillPopScope(
              child: AlertDialog(
                title: Text('Congratulations! You clicked $args times'),
              ),
              onWillPop: () async {
                // Argument that Navigator.pop() function will be returned to the Bloc     
                Navigator.of(context).pop('Dialog with $args clicks has been closed');
                return false;
              });
        });
  },
)

class CounterBloc extends Bloc {

  ...
  void increment() {
    addState<bool>(true);
    addStateSource<int>(repo.increment(),
        onData: (count) async {
          // print String that was passed to Navigator.pop()
          print(await addNavigation(arguments: count));
        },
        onDone: () => addState<bool>(false));
  }
  ...
}
``` 

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

If you have some `Future` or `Stream` that contains state objects you can pass it as state source 
with help `addStatesSource()` and `addStateSource()` 
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
      addStateSource<int>(repo.increment(),
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
