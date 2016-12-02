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
abstract Middleware<State, Action>(MiddlewareF<State, Action>) from MiddlewareF<State, Action> to MiddlewareF<State, Action> {
  @:op(A+B)
  public function compose(other: Middleware<State, Action>): Middleware<State, Action> {
    return function(state: State, action: Action) {
      return Promise.sequence([
        this(state, action),
        other(state, action)
      ]).map(function(actions) {
        return actions.flatten();
      });
    };
  }

  @:from
  public static function withActionOnly<State, Action>(f: Action -> Promise<Array<Action>>): Middleware<State, Action>
    return function(_: State, action) return f(action);

  @:from
  public static function withActionOnlyAndOneResult<State, Action>(f: Action -> Promise<Action>): Middleware<State, Action>
    return function(_: State, action) return f(action).map(function(v) return [v]);

  @:from
  public static function withActionOnlySync<State, Action>(f: Action -> Array<Action>): Middleware<State, Action>
    return function(_: State, action) return Promise.value(f(action));

  @:from
  public static function withActionOnlyAndOneResultSync<State, Action>(f: Action -> Action): Middleware<State, Action>
    return function(_: State, action) return Promise.value([f(action)]);

  @:from
  public static function withOneResult<State, Action>(f: State -> Action -> Promise<Action>): Middleware<State, Action>
    return function(state: State, action) return f(state, action).map(function(v) return [v]);

  @:from
  public static function sync<State, Action>(f: State -> Action -> Array<Action>): Middleware<State, Action>
    return function(state: State, action) return Promise.value(f(state, action));
}

typedef MiddlewareF<State, Action> = State -> Action -> Promise<Array<Action>>;
