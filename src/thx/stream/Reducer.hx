package thx.stream;

using thx.promise.Promise;
using thx.Arrays;

@:callable
abstract Reducer<State, Action>(ReducerF<State, Action>) from ReducerF<State, Action> to ReducerF<State, Action> {
  @:op(A+B)
  public function compose(other: Reducer<State, Action>): Reducer<State, Action> {
    return function(state: State, action: Action) {
      return other(this(state, action), action);
    };
  }
}

typedef ReducerF<State, Action> = State -> Action -> State;

@:callable
abstract Middleware<Action>(MiddlewareF<Action>) from MiddlewareF<Action> to MiddlewareF<Action> {
  @:op(A+B)
  public function compose(other: Middleware<Action>): Middleware<Action> {
    return function(action: Action) {
      return Promise.sequence([
        this(action),
        other(action)
      ]).map(function(actions) {
        return actions.flatten();
      });
    };
  }
}

typedef MiddlewareF<Action> = Action -> Promise<Array<Action>>;
