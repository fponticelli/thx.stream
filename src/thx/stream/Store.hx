package thx.stream;

using thx.promise.Promise;
import thx.stream.Reducer;

class Store<State, Action> {
  var property: Property<State>;
  var reducer: Reducer<State, Action>;
  var middleware: Middleware<Action>;
  public function new(reducer: Reducer<State, Action>, ?middleware: Middleware<Action>, initial: State, ?equality: State -> State -> Bool) {
    property = new Property(initial, equality);
    this.reducer = reducer;
    this.middleware = null != middleware ? middleware : function(_) return Promise.value([]);
  }

  public function apply(action: Action, ?pos: haxe.PosInfos) {
    try {
      var newValue = reducer(get(), action);
      property.set(newValue);
      middleware(action)
        .success(function(actions) actions.map(apply.bind(_, pos)))
        .failure(property.error);
    } catch(e: Dynamic) {
      property.error(thx.Error.fromDynamic(e, pos));
    }
    return this;
  }

  public function stream()
    return property.stream();

  public function get()
    return property.get();
}
