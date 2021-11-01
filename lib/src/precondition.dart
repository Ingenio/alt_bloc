/// Signature of predicate function that use to compare states of [Bloc].
typedef Precondition<S> = bool Function(S previousState, S newState);
