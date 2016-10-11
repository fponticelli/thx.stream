package thx.stream;

import thx.Error;
import thx.stream.Stream;
using thx.Arrays;

class Emitter<T> {
  public static function create<T>(): StreamEmitter<T>
    return new StreamEmitter(BufferStream.new.bind(_, []));

  public static function last<T>(): StreamEmitter<T>
    return new StreamEmitter(LastStream.new);

  public static function volatile<T>(): StreamEmitter<T>
    return new StreamEmitter(VolatileStream.new);

  var notify: StreamValue<T> -> Void;
  function new(notify: StreamValue<T> -> Void) {
    this.notify = notify;
  }

  public function send(value: StreamValue<T>) {
    try {
      notify(value);
      switch value {
        case Error(_) | Done(_):
          silence();
        case _:
      }
    } catch(e: Dynamic) switch value {
      case Value(_):
        // try to terminate chain on failing subscriber
        send(Error(thx.Error.fromDynamic(e)));
      case _:
        silence(); // stop listening
        throw new thx.error.ErrorWrapper('Error in stream handler for Error or Done', e);
    }
  }

  function silence() //{}
    notify = function(_) {};

  public function next(value: T): Void
    send(Value(value));

  public function done(canceled: Bool): Void
    send(Done(canceled));

  public function complete(): Void
    done(false);

  public function error(e: Error): Void
    send(Error(e));

  public function cancel(): Void
    done(true);
}

class StreamEmitter<T> extends Emitter<T> {
  public var stream(default, null): Stream<T>;
  public function new(streamf: (Void -> Void) -> SubscriberStream<T>) {
    var s = streamf(this.cancel);
    this.stream = s;
    super(s.notify);
  }
}
