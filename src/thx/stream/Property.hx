package thx.stream;

class Property<T> {
  public var value(default, null): T;

  var equals: T -> T -> Bool;
  var emitters: Array<T -> Void>;

  public function new(initial: T, ?equals: T -> T -> Bool) {
    this.equals = null == equals ? Functions.equality : equals;
    this.emitters = [];
    set(initial);
  }

  public function set(value: T) {
    if(equals(this.value, value))
      return;
    this.value = value;
    emit(value);
  }

  function emit(value: T) {
    for(e in emitters)
      e(value);
  }
  public function stream(): Stream<T> {
    return Stream.cancellable(function(o, addCancel) {
      var e = o.next;
      emitters.push(e);
      e(value);
      addCancel(function() {
        emitters.remove(e);
      });
    });
  }
}
