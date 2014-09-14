package thx.stream;

import haxe.ds.Option;
import thx.core.Options;

class Value<T> extends Emitter<T> {
  public static function createOption<T>(?value : T, ?equal : T -> T -> Bool) {
    var def = null == value ? None : Some(value);
    return new Value<Option<T>>(def, Options.equals.bind(_, _, equal));
  }

  var value : T;
  var downStreams : Array<Stream<T>>;
  var upStreams : Array<Stream<T>>;
  var equal : T -> T -> Bool;
  public function new(value : T, ?equal : T -> T -> Bool) {
    this.equal = null == equal ? function(a, b) return a == b : equal;
    this.value = value;
    this.downStreams = [];
    this.upStreams = [];
    super(function(stream : Stream<T>) {
      this.downStreams.push(stream);
      stream.addCleanUp(function() this.downStreams.remove(stream));
      stream.pulse(this.value);
    });
  }

  public function get() : T
    return value;

  public function set(value : T) {
    if(equal(this.value, value))
      return;
    this.value = value;
    update();
  }

  public function clearStreams()
    for(stream in downStreams.copy())
      stream.end();

  public function clearEmitters()
    for(stream in upStreams.copy())
      stream.cancel();

  public function clear() {
    clearEmitters();
    clearStreams();
  }

  function update()
    for(stream in downStreams.copy())
      stream.pulse(value);
}