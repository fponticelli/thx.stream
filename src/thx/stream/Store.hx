package thx.stream;

using thx.Arrays;
using thx.promise.Promise;
import thx.stream.Reducer;

class Store<State, Action> {
  public static function withReducer<State, Action>(reducer: Reducer<State, Action>, initial: State, ?equality: State -> State -> Bool) {
    var property = new Property(initial, equality);
    return new Store(property, reducer, Middleware.empty());
  }

  public static function withMiddleware<State, Action>(reducer: Reducer<State, Action>, middleware: Middleware<State, Action>, initial: State, ?equality: State -> State -> Bool) {
    var property = new Property(initial, equality);
    return new Store(property, reducer, middleware);
  }

  var property: Property<State>;
  var reducer: Reducer<State, Action>;
  var middleware: Middleware<State, Action>;

  public function new(property: Property<State>, reducer: Reducer<State, Action>, middleware: Middleware<State, Action>) {
    this.property = property;
    this.reducer = reducer;
    this.middleware = middleware;
  }

  public function dispatch(action: Action, ?pos: haxe.PosInfos): Store<State, Action> {
    try {
      var newValue = reducer(get(), action);
      property.set(newValue);
      middleware(property.get(), action, function(a) dispatch(a, pos));
    } catch(e: Dynamic) {
      property.error(thx.Error.fromDynamic(e, pos));
    }
    return this;
  }

  public function dispatcher(?pos: haxe.PosInfos) {
    return dispatch.bind(_, pos);
  }

  public function stream()
    return property.stream();

  public function get()
    return property.get();


}
