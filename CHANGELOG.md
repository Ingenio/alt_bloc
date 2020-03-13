## [0.1.0] - 2020/01/28

* Bloc design pattern solution. Implements Bloc with multi states feature. 
Implements widgets that improve work with Bloc such as BlocProvider, Provider, BlocBuilder, RouteListener.

## [0.1.1] - 2020/01/29
* Implements Bloc feature that provide possibility pass Stream or Future as source of states. To 
use this feature you need to call `StreamSubscription<S> addStreamSource<S>(Stream<S> 
source)` or `StreamSubscription<S> addFutureSource<S>(Future<S> source)`.

## [0.1.1+1] - 2020/02/02
* All pub.dev health suggestions have been resolved.

## [0.1.1+2] - 2020/02/15
* `addStreamSource<S>()` and `addFutureSource<S>()` methods have been improved. New arguments 
that allow listen for source future/stream state have been added.

## [0.1.2] - 2020/02/26
* `addNavigation<R>()` method has been improved and returns a Future that completes to the result
 value passed to `Navigator.pop()` when the pushed route is popped off the navigator.
* Bloc methods `registerState`, `initialState`, `addNavigation`, `addState`, `addStreamSource` and
 `addFutureSource` were marked as protected.
 
## [0.1.2+1] - 2020/03/04
* Issue with navigation events loss has been fixed.

## [0.1.2+2] - 2020/03/04
*  Hotfix of navigation events processing flow.

## [0.1.2+3] - 2020/03/13
* Issue with throwing `ArgumentError` after call `addState` method for disposed bloc has been
 fixed. 

