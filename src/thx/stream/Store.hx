package thx.stream;

using thx.promise.Promise;
import thx.stream.Reducer;

class Store<State, Action> {
  var property: Property<State>;
  var reducer: Reducer<State, Action>;
  var middleware: Middleware<State, Action>;
  public function new(reducer: Reducer<State, Action>, ?middleware: Middleware<State, Action>, initial: State, ?equality: State -> State -> Bool) {
    property = new Property(initial, equality);
    this.reducer = reducer;
    this.middleware = null != middleware ? middleware : function(_, _) return Promise.value([]);
  }

  public function dispatch(action: Action, ?pos: haxe.PosInfos) {
    try {
      var newValue = reducer(get(), action);
      property.set(newValue);
      middleware(property.get(), action)
        .success(function(actions) actions.map(dispatch.bind(_, pos)))
        .failure(property.error);
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
