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