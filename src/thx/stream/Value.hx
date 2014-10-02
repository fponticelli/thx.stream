package thx.stream;

import haxe.ds.Option;
import thx.core.Options;

// TODO: value lens
class Value<T> extends Emitter<T> {
  #if java @:generic #end
  public static function createOption<T>(?value : T, ?equals : T -> T -> Bool) {
    var def = Options.toOption(value);
    return new Value<Option<T>>(def, function(a, b) return Options.equals(a, b, equals));
  }

  var value : T;
  var downStreams : Array<Stream<T>>;
  var upStreams : Array<Stream<T>>;
  var equals : T -> T -> Bool;
  public function new(value : T, ?equals : T -> T -> Bool) {
    this.equals = null == equals ? function(a, b) return a == b : equals;
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
    if(equals(this.value, value))
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