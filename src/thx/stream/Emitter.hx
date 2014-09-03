package thx.stream;

import thx.core.Error;
import thx.core.Timer;
import thx.promise.Promise;

class Emitter<T> {
  public static function create<T>(init : Stream<T> -> Void) : Emitter<T> {
    return new Emitter(init);
  }

  var init : Stream<T> -> Void;
  function new(init : Stream<T> -> Void) {
    this.init = init;
  }

  public function sign(subscriber : StreamValue<T> -> Void) : Stream<T> {
    var stream = new Stream(subscriber);
    init(stream);
    return stream;
  }

  public function subscribe(?pulse : T -> Void, ?fail : Error -> Void, ?end : Bool -> Void) {
    pulse = null != pulse ? pulse : function(_) {};
    fail = null != fail ? fail : function(_) {};
    end = null != end ? end : function(_) {};
    var stream = new Stream(function(r) switch r {
      case Pulse(v): pulse(v);
      case Failure(e): fail(e);
      case End(c): end(c);
    });
    init(stream);
    return stream;
  }

  public function delay(time : Int)
    return new Emitter(function(stream) {
      Timer.delay(function() init(stream), time);
    });

  public function map<TOut>(f : T -> Promise<TOut>) : Emitter<TOut>
    return new Emitter(function(stream) {
      init(new Stream(function(r) switch r {
        case Pulse(v):
          f(v).either(
            function(vout) stream.pulse(vout),
            function(err)  stream.fail(err)
          );
        case Failure(e):   stream.fail(e);
        case End(true):    stream.cancel();
        case End(false):   stream.end();
      }));
    });

  public function mapValue<TOut>(f : T -> TOut) : Emitter<TOut>
    return map(function(v) return Promise.value(f(v)));

  public function takeUntil(f : T -> Promise<Bool>) : Emitter<T>
    return new Emitter(function(stream) {
      init(new Stream(function(r) switch r {
        case Pulse(v):
          f(v).either(
            function(c) if(c) {
              stream.pulse(v);
            } else {
              stream.end();
            },
            function(err) stream.fail(err)
          );
        case Failure(e):   stream.fail(e);
        case End(true):    stream.cancel();
        case End(false):   stream.end();
      }));
    });

  public function take(count : Int)
    return takeUntil({
      var counter = 0;
      function(_) return Promise.value(counter++ < count);
    });
}