package thx.stream;

using thx.stream.Observer;

class Property<T> {
  var value: T;
  var equals: T -> T -> Bool;
  var emitters: Array<T -> Void>;

  public function new(initial: T, ?equals: T -> T -> Bool) {
    this.equals = null == equals ? Functions.equality : equals;
    this.emitters = [];
    set(initial);
  }

  public function modify(f: T -> T) {
    var newValue = f(value);
    if(equals(value, newValue))
      return;
    value = newValue;
    emit(newValue);
  }

  public function get(): T
    return value;

  public function set(value: T)
    modify(function(_) return value);

  function emit(value: T)
    for(e in emitters)
      e(value);

  public function stream(): Stream<T>
    return Stream.cancellable(function(o, addCancel) {
      var e = o.next;
      emitters.push(e);
      e(value);
      addCancel(function() {
        emitters.remove(e);
      });
    });
}
