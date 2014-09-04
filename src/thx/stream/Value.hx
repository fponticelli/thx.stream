package thx.stream;

class Value<T> extends Emitter<T> {
  var value : T;
  var downStreams : Array<Stream<T>>;
  var upStreams : Array<Stream<T>>;
  public function new(value : T) {
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
    if(this.value == value)
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