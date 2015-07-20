package thx.stream;

class Streams {
  public static function toStream<T>(values : Array<T>) : Emitter<T> {
    return new Emitter(function(stream) {
      for(value in values) {
        if(stream.canceled) return;
        stream.pulse(value);
      }
      stream.end();
    });
  }
}