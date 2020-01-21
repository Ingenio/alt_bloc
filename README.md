# alt_bloc
Library for BLoC design pattern implementation. Inspired by [BLoC](https://pub.dev/packages/bloc), [Provider](https://pub.dev/packages/provider) libraries and my own experience of Flutter development.

## Main Features
- public interface of **alt_bloc** similar to interface of popular libraries like **Provider** and **BLoC**. So you no need spend a lot of time to learn how set up this library.
- Support multistates. You can create few states per **Bloc** and you don't need create hierarchy of states that inherited from one parent state, especially if this states on different levels of abstraction.
- Contains separate pipe to handle navigation actions.

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
`typedef Router = Function(BuildContext context, String name, dynamic args);` - function that responsible for receiving and handling navigation events.

  
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




