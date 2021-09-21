## [2.1.0+2] - 2021/09/21
* Throwing of StateError in case if Bloc was disposed has been removed.

## [2.1.0+1] - 2021/08/31 
* **HOT FIX**  ConcurrentModificationError that appear during iteration by subscribers controllers 
  collection has been fixed.
  
## [2.1.0] - 2021/08/27
* Bloc entity has been redesigned and state delivery system has been improved.
* **BREAKING CHANGES** `isBroadcast` argument has been removed, you no need it anymore.
* **BREAKING CHANGES** `RouteData` class has been refactored and normalized. No need call 
  `settings` property to receive `name` or `arguments` of route, they available directly from 
  `RouteData` object.

## [2.0.1] - 2021/08/25
* Obtaining Bloc by Provider has been improved.
* Property 'asyncNavigation' that change navigation stream as sync/async has been added. Sync by 
  default.  

## [2.0.0] - 2021/03/09
* Null safety release.

## [2.0.0-nullsafety.0] - 2020/11/28
* Migration to Dart null safety.

## [1.0.0+3] - 2020/10/09
* **HOT FIX** Error `NoSuchMethodError: The method 'then' was called on null.` that has been thrown
 when `BlocRouter` returns `null` has been fixed.

## [1.0.0+2] - 2020/10/09
* **BREAKING CHANGES** Router function has been renamed to BlocRouter to avoid namespace conflict
 with Router widget that was added in Flutter 1.22.
* Navigation typecast issue that appear when pass concrete type to generic parameter for
 addNavigation() method has been fixed.
 
## [1.0.0+1] - 2020/04/28
* code format
* README.md update

## [1.0.0] - 2020/04/28 - Major release
* New `BlocConsumer` widget has been implemented.
* `BlocBuilder`, `BlocProvider` and `RouteListener` widgets have been refactored.
* `Bloc` public interface has been redesigned.
* New `Bloc` methods and properties have been added: `Bloc.isDisposed`, `Bloc.containsState()`,
 `Bloc.addNavigationSource()`.
* **BREAKING CHANGES** The way access to state and navigation events of `Bloc` has been changed. `Bloc
.listenNavigation()` method has been changed to `Bloc.navigationStream` property. `Bloc.listenState()` has been
 changed to `Bloc.getStateStream()`.
* **BREAKING CHANGES** Method `Bloc.addStreamSource()` has been renamed to `Bloc.addStatesSource()`.
* **BREAKING CHANGES** Method `Bloc.addFutureSource()` has been renamed to `Bloc.addStateSource()`.

## [0.1.2+3] - 2020/03/13
* Issue with throwing `ArgumentError` after call `addState` method for disposed bloc has been
 fixed.
 
## [0.1.2+2] - 2020/03/04
*  Hotfix of navigation events processing flow.

## [0.1.2+1] - 2020/03/04
* Issue with navigation events loss has been fixed.

## [0.1.2] - 2020/02/26
* `addNavigation<R>()` method has been improved and returns a Future that completes to the result
 value passed to `Navigator.pop()` when the pushed route is popped off the navigator.
* Bloc methods `registerState`, `initialState`, `addNavigation`, `addState`, `addStreamSource` and
 `addFutureSource` were marked as protected.
 
## [0.1.1+2] - 2020/02/15
* `addStreamSource<S>()` and `addFutureSource<S>()` methods have been improved. New arguments 
that allow listen for source future/stream state have been added.

## [0.1.1+1] - 2020/02/02
* All pub.dev health suggestions have been resolved.

## [0.1.1] - 2020/01/29
* Implements Bloc feature that provide possibility pass Stream or Future as source of states. To 
use this feature you need to call `StreamSubscription<S> addStreamSource<S>(Stream<S> 
source)` or `StreamSubscription<S> addFutureSource<S>(Future<S> source)`.

## [0.1.0] - 2020/01/28
* Bloc design pattern solution. Implements Bloc with multi states feature. 
Implements widgets that improve work with Bloc such as BlocProvider, Provider, BlocBuilder, RouteListener.








 




 

