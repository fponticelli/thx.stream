package thx.stream;

import thx.Functions;
import thx.stream.Emitter;

class Property<T> {
  public var stream(default, null): Stream<T>;
  public var value(default, null): T;

  var equals: T -> T -> Bool;
  public function new(initial: T, ?equals: T -> T -> Bool) {
    this.equals = null == equals ? Functions.equality : equals;
    set(initial);
  }

  public function set(value: T) {
    if(equals(this.value, value))
      return;
    this.value = value;
    // emitter.next(value);
  }

  public function stream(): Stream<T> {
    return Stream.create(function(o) {
      
    });
  }
}
