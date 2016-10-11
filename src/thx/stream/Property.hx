package thx.stream;

import thx.Functions;
import thx.stream.Emitter;

class Property<T> {
  public var stream(default, null): Stream<T>;
  public var value(default, null): T;

  var equality: T -> T -> Bool;
  var emitter: StreamEmitter<T>;
  public function new(initial: T, ?equality: T -> T -> Bool) {
    this.emitter = Emitter.last();
    this.stream = emitter.stream;
    this.equality = null == equality ? Functions.equality : equality;
    set(initial);
  }

  public function set(value: T) {
    if(equality(this.value, value))
      return;
    this.value = value;
    emitter.next(value);
  }
}
