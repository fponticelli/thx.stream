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
    return function(state: State, action: Action, f: Action -> Void) {
      this(state, action, f);
      other(state, action, f);
    };
  }

  @:from
  public static function onlyAction<State, Action>(f: Action -> (Action -> Void) -> Void): Middleware<State, Action>
    return function(_: State, action: Action, dispatch: Action -> Void) return f(action, dispatch);

  @:from
  public static function onlyState<State, Action>(f: State -> (Action -> Void) -> Void): Middleware<State, Action>
    return function(state: State, _: Action, dispatch: Action -> Void) return f(state, dispatch);

/*
  @:from
  public static function withActionOnlyAndOneResult<State, Action>(f: Action -> Promise<Action>): Middleware<State, Action>
    return function(_: State, action: Action) return [f(action)];

  @:from
  public static function withActionOnlySync<State, Action>(f: Action -> Array<Action>): Middleware<State, Action>
    return function(_: State, action: Action) return f(action).map(Promise.value);

  @:from
  public static function withActionOnlyAndOneResultSync<State, Action>(f: Action -> Action): Middleware<State, Action>
    return function(_: State, action: Action) return [Promise.value(f(action))];

  @:from
  public static function withOneResult<State, Action>(f: State -> Action -> Promise<Action>): Middleware<State, Action>
    return function(state: State, action: Action) return [f(state, action)];

  @:from
  public static function sync<State, Action>(f: State -> Action -> Array<Action>): Middleware<State, Action>
    return function(state: State, action: Action) return f(state, action).map(Promise.value);

  @:from
  public static function sideEffectBoth<State, Action>(f: State -> Action -> Void): Middleware<State, Action>
    return function(state: State, action: Action) { f(state, action); return []; };
*/

  @:from
  public static function sideEffect<State, Action>(f: State -> Action -> Void): Middleware<State, Action>
    return function(state: State, action: Action, _) f(state, action);

  @:from
  public static function sideEffectState<State, Action>(f: State -> Void): Middleware<State, Action>
    return function(state: State, _: Action, _) f(state);

  @:from
  public static function sideEffectAction<State, Action>(f: Action -> Void): Middleware<State, Action>
    return function(_: State, action: Action, _) f(action);

  public static function empty<State, Action>(): Middleware<State, Action>
    return function(_: State, _: Action, f) {};
}

typedef MiddlewareF<State, Action> = State -> Action -> (Action -> Void) -> Void;
