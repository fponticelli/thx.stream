package thx.stream;

import thx.core.Error;

class Bus<T> extends Emitter<T> {
  var downStreams : Array<Stream<T>>;
  var upStreams : Array<Stream<T>>;
  public function new() {
    this.downStreams = [];
    this.upStreams = [];
    super(function(stream : Stream<T>) {
      this.downStreams.push(stream);
      stream.addCleanUp(function() this.downStreams.remove(stream));
    });
  }

  public function emit(value : StreamValue<T>) switch value {
    case Pulse(v):
      for(stream in downStreams.copy())
        stream.pulse(v);
    case Failure(e):
      for(stream in downStreams.copy())
        stream.fail(e);
    case End(true):
      for(stream in downStreams.copy())
        stream.cancel();
    case End(false):
      for(stream in downStreams.copy())
        stream.end();
  }

  inline public function pulse(value : T)
    emit(Pulse(value));

  inline public function fail(error : Error)
    emit(Failure(error));

  inline public function end()
    emit(End(false));

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
}