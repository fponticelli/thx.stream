package thx.stream;

import haxe.ds.Option;
import thx.core.Error;
import thx.core.Nil;
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
        case Failure(e):  stream.fail(e);
        case End(true):   stream.cancel();
        case End(false):  stream.end();
      }));
    });

  public function take(count : Int)
    return takeUntil({
      var counter = 0;
      function(_) return Promise.value(counter++ < count);
    });

  public function audit(handler : T -> Void) : Emitter<T>
    return mapValue(function(v) {
      handler(v);
      return v;
    });

  public function filter(f : T -> Promise<Bool>) : Emitter<T>
    return new Emitter(function(stream) {
      init(new Stream(function(r) switch r {
        case Pulse(v):
          f(v).either(
            function(c)   if(c) stream.pulse(v),
            function(err) stream.fail(err)
          );
        case Failure(e):  stream.fail(e);
        case End(true):   stream.cancel();
        case End(false):  stream.end();
      }));
    });

  public function filterValue(f : T -> Bool) : Emitter<T>
    return filter(function(v) return Promise.value(f(v)));

  public function concat(other : Emitter<T>) : Emitter<T>
    return new Emitter(function(stream) {
      init(new Stream(function(r) switch r {
        case Pulse(v):    stream.pulse(v);
        case Failure(e):  stream.fail(e);
        case End(true):   stream.cancel();
        case End(false):  other.init(stream);
      }));
    });

  public function merge(other : Emitter<T>) : Emitter<T>
    return new Emitter(function(stream : Stream<T>) {
      init(stream);
      other.init(stream);
    });

  public function toOption() : Emitter<Option<T>>
    return mapValue(function(v) return null == v ? None : Some(v));
  public function toNil() : Emitter<Nil>
    return mapValue(function(_) return nil);
  public function toTrue() : Emitter<Bool>
    return mapValue(function(_) return true);
  public function toFalse() : Emitter<Bool>
    return mapValue(function(_) return false);
  public function log(?prefix : String, ?posInfo : haxe.PosInfos) {
    prefix = prefix == null ? '': '${prefix}: ';
    return mapValue(function(v) {
      haxe.Log.trace('$prefix$v', posInfo);
      return v;
    });
  }

  public function withValue(?expected : T) : Emitter<T>
    return filterValue(
      null == expected ?
        function(v : T) return v != null :
        function(v : T) return v == expected
    );

// blend
// keep
// debounce
// sampleBy
// pair
// distinct
// merge
// sync
// zip
// previous
// public function window(length : Int, fillBeforeEmit = false) : Producer<T> // or unique
// public function reduce(acc : TOut, TOut -> T) : Producer<TOut>
// public function debounce(delay : Int) : Producer<T>
// exact pair
// public function zip<TOther>(other : Producer<TOther>) : Producer<Tuple<T, TOther>> // or sync

// mapFilter?

/*
  public static function filterOption<T>(producer : Producer<Option<T>>) : Producer<T>
    return producer
      .filter(function(opt) return switch opt { case Some(_): true; case None: false; })
      .map(function(opt) return switch opt { case Some(v) : v; case None: throw 'filterOption failed'; });

  public static function toValue<T>(producer : Producer<Option<T>>) : Producer<Null<T>>
    return producer
      .map(function(opt) return switch opt { case Some(v) : v; case None: null; });

  public static function toBool<T>(producer : Producer<Option<T>>) : Producer<Bool>
    return producer
      .map(function(opt) return switch opt { case Some(_) : true; case None: false; });

  public static function skipNull<T>(producer : Producer<Null<T>>) : Producer<T>
    return producer
      .filter(function(value) return null != value);

  public static function left<TLeft, TRight>(producer : Producer<Tuple2<TLeft, TRight>>) : Producer<TLeft>
    return producer.map(function(v) return v._0);

  public static function right<TLeft, TRight>(producer : Producer<Tuple2<TLeft, TRight>>) : Producer<TRight>
    return producer.map(function(v) return v._1);

  public static function negate(producer : Producer<Bool>)
    return producer.map(function(v) return !v);

  public static function flatMap<T>(producer : Producer<Array<T>>) : Producer<T> {
    return new Producer(function(forward : Pulse<T> -> Void) {
      producer.feed(Bus.passOn(
        function(arr : Array<T>) arr.map(function(value) forward(Emit(value))),
        forward
      ));
    }, producer.endOnError);
  }

  public static function delayed<T>(producer : Producer<T>, delay : Int) : Producer<T> {
    return new Producer(function(forward) {
      producer.feed(new Bus(
        function(v)
          Timer.setTimeout(function() forward(Emit(v)), delay),
        function()
          Timer.setTimeout(function() forward(End), delay),
        function(error)
          Timer.setTimeout(function() forward(Fail(error)), delay)
      ));
    }, producer.endOnError);
  }

@:access(steamer.Producer)
class ProducerProducer {
  public static function flatMap<T>(producer : Producer<Producer<T>>) : Producer<T> {
    return new Producer(function(forward : Pulse<T> -> Void) {
      producer.feed(Bus.passOn(
        function(prod : Producer<T>) {
          prod.feed(Bus.passOn(
            function(value : T) forward(Emit(value)),
            forward
          ));
        },
        forward
      ));
    }, producer.endOnError);
  }
}

class StringProducer {
  public static function toBool(producer : Producer<String>) : Producer<Bool>
    return producer
      .map(function(s) return s != null && s != "");
}
*/
}
