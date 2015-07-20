package thx.stream;

using thx.promise.Promise;

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

class StreamArrays {
  public static function toStream<T>(promise : Promise<Array<T>>) : Emitter<T> {
    return new Emitter(function(stream) {
      promise
        .success(function(values) {
          for(value in values) {
            if(stream.canceled) return;
            stream.pulse(value);
          }
          stream.end();
        })
        .failure(function(err) {
          throw err;
        });
    });
  }
}
