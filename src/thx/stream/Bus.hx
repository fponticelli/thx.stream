package thx.stream;

import thx.core.Error;

class Bus<T> extends Emitter<T> {
  var downStreams : Array<Stream<T>>;
  var upStreams : Array<Stream<T>>;
  var distinctValuesOnly : Bool;
  var equal : T -> T -> Bool;
  var value : Null<T>;
  public function new(distinctValuesOnly = false, ?equal : T -> T -> Bool) {
    this.distinctValuesOnly = distinctValuesOnly;
    this.equal = null == equal ? function(a, b) return a == b : equal;
    this.downStreams = [];
    this.upStreams = [];
    super(function(stream : Stream<T>) {
      this.downStreams.push(stream);
      stream.addCleanUp(function() this.downStreams.remove(stream));
    });
  }

  inline public function cancel()
    emit(End(true));

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

  public function emit(value : StreamValue<T>) switch value {
    case Pulse(v):
      if(distinctValuesOnly) {
        if(equal(v, this.value))
          return;
        this.value = v;
      }
      for(stream in downStreams.copy())
        stream.pulse(v);
    case End(true):
      for(stream in downStreams.copy())
        stream.cancel();
    case End(false):
      for(stream in downStreams.copy())
        stream.end();
  }

  inline public function end()
    emit(End(false));

  inline public function pulse(value : T)
    emit(Pulse(value));
}