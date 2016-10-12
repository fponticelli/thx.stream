package thx.stream;

import thx.Functions;
import thx.stream.Emitter;

class Property<T> {
  public var stream(default, null): Stream<T>;
  public var value(default, null): T;

  var equals: T -> T -> Bool;
  var emitter: StreamEmitter<T>;
  public function new(initial: T, ?equals: T -> T -> Bool) {
    this.emitter = Emitter.last();
    this.stream = emitter.stream;
    this.equals = null == equals ? Functions.equality : equals;
    set(initial);
  }

  public function set(value: T) {
    if(equals(this.value, value))
      return;
    this.value = value;
    emitter.next(value);
  }
}
