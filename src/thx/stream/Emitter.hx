package thx.stream;

import haxe.ds.Option;
import thx.core.Error;
import thx.core.Nil;
import thx.core.Timer in T;
import thx.core.Timer.TimerID;
import thx.promise.Promise;
using thx.core.Options;
using thx.core.Tuple;

class Emitter<T> {
  public static function create<T>(init : Stream<T> -> Void) : Emitter<T> {
    return new Emitter(init);
  }

  var init : Stream<T> -> Void;
  function new(init : Stream<T> -> Void) {
    this.init = init;
  }

  public function sign(subscriber : StreamValue<T> -> Void) : IStream {
    var stream = new Stream(subscriber);
    init(stream);
    return stream;
  }

  public function subscribe(?pulse : T -> Void, ?fail : Error -> Void, ?end : Bool -> Void) : IStream {
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

  @:access(thx.stream.Value)
  @:access(thx.stream.Stream)
  public function feed(value : Value<T>) : IStream {
    var stream : Stream<T> = new Stream(null);
    stream.subscriber = function(r) switch r {
      case Pulse(v): value.set(v);
      case Failure(e): stream.fail(e);
      case End(c): if(c) stream.cancel() else stream.end();
    };
    value.upStreams.push(stream);
    stream.addCleanUp(function() value.upStreams.remove(stream));
    init(stream);
    return stream;
  }

  @:access(thx.stream.Bus)
  @:access(thx.stream.Stream)
  public function plug(bus : Bus<T>) : IStream {
    var stream : Stream<T> = new Stream(null);
    stream.subscriber = bus.emit;
    bus.upStreams.push(stream);
    stream.addCleanUp(function() bus.upStreams.remove(stream));
    init(stream);
    return stream;
  }

  public function delay(time : Int)
    return new Emitter(function(stream) {
      var id = T.delay(function() init(stream), time);
      stream.addCleanUp(T.clear.bind(id));
    });

  public function debounce(delay : Int)
    return new Emitter(function(stream) {
      var id : TimerID = null;
      stream.addCleanUp(function() T.clear(id));
      init(new Stream(function(r : StreamValue<T>) {
        switch r {
          case Pulse(v):
            T.clear(id);
            id = T.delay(stream.pulse.bind(v), delay);
          case Failure(e): stream.fail(e);
          case End(true):  stream.cancel();
          case End(false): T.delay(stream.end, delay);
        }
      }));
    });

  public function map<TOut>(f : T -> Promise<TOut>) : Emitter<TOut>
    return new Emitter(function(stream) {
      init(new Stream(function(r) {
        switch r {
        case Pulse(v):
          f(v).either(
            function(vout) stream.pulse(vout),
            function(err)  stream.fail(err)
          );
        case Failure(e):   stream.fail(e);
        case End(true):    stream.cancel();
        case End(false):   stream.end();
      }}));
    });

  public function mapValue<TOut>(f : T -> TOut) : Emitter<TOut>
    return map(function(v) return Promise.value(f(v)));

  // TODO ... have a look at those nasty instream
  public function takeUntil(f : T -> Promise<Bool>) : Emitter<T>
    return new Emitter(function(stream) {
      var instream : Stream<T> = null;
      instream = new Stream(function(r : StreamValue<T>) switch r {
        case Pulse(v):
          f(v).either(
            function(c : Bool) if(c) {
              stream.pulse(v);
            } else {
              instream.end();
              stream.end();
            },
            stream.fail
          );
        case Failure(e):
          instream.fail(e);
          stream.fail(e);
        case End(true):
          instream.cancel();
          stream.cancel();
        case End(false):
          instream.end();
          stream.end();
      });
      this.init(instream);
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

  public function reduce<TOut>(acc : TOut, f : TOut -> T -> TOut) : Emitter<TOut>
    return new Emitter(function(stream) {
      init(new Stream(function(r) switch r {
        case Pulse(v):
          acc = f(acc, v);
          stream.pulse(acc);
        case Failure(e):  stream.fail(e);
        case End(true):   stream.cancel();
        case End(false):  stream.end();
      }));
    });

  public function toOption() : Emitter<Option<T>>
    return mapValue(function(v) return null == v ? None : Some(v));
  public function toNil() : Emitter<Nil>
    return mapValue(function(_) return nil);
  public function toTrue() : Emitter<Bool>
    return mapValue(function(_) return true);
  public function toFalse() : Emitter<Bool>
    return mapValue(function(_) return false);
  public function toValue<T>(value : T) : Emitter<T>
    return mapValue(function(_) return value);
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

  public function distinct(?equals : T -> T -> Bool) : Emitter<T>
    return new Emitter(function(stream) {
      if(null == equals)
        equals = function(a, b) return a == b;
      var last : T = null;
      init(new Stream(function(r) switch r {
        case Pulse(v):
          if(equals(v, last))
            return;
          last = v;
          stream.pulse(v);
        case Failure(e):  stream.fail(e);
        case End(true):   stream.cancel();
        case End(false):  stream.end();
      }));
    });

  public function pair<TOther>(other : Emitter<TOther>) : Emitter<Tuple2<T, TOther>>
    return new Emitter(function(stream) {
      var _0 : Null<T> = null,
          _1 : Null<TOther> = null;
      stream.addCleanUp(function() {
        _0 = null;
        _1 = null;
      });
      function pulse() {
        if(null == _0 || null == _1)
          return;
        stream.pulse(new Tuple2(_0, _1));
      }
      init(new Stream(function(r) switch r {
        case Pulse(v):
          _0 = v;
          pulse();
        case Failure(e):  stream.fail(e);
        case End(true):   stream.cancel();
        case End(false):  stream.end();
      }));
      other.init(new Stream(function(r) switch r {
        case Pulse(v):
          _1 = v;
          pulse();
        case Failure(e):  stream.fail(e);
        case End(true):   stream.cancel();
        case End(false):  stream.end();
      }));
    });

  public function zip<TOther>(other : Emitter<TOther>) : Emitter<Tuple2<T, TOther>>
    return new Emitter(function(stream) {
      var _0 : Array<T> = [],
          _1 : Array<TOther> = [];
      stream.addCleanUp(function() {
        _0 = null;
        _1 = null;
      });
      function pulse() {
        if(_0.length == 0 || _1.length == 0)
          return;
        stream.pulse(new Tuple2(_0.shift(), _1.shift()));
      }
      init(new Stream(function(r) switch r {
        case Pulse(v):
          _0.push(v);
          pulse();
        case Failure(e):  stream.fail(e);
        case End(true):   stream.cancel();
        case End(false):  stream.end();
      }));
      other.init(new Stream(function(r) switch r {
        case Pulse(v):
          _1.push(v);
          pulse();
        case Failure(e):  stream.fail(e);
        case End(true):   stream.cancel();
        case End(false):  stream.end();
      }));
    });

  public function sampleBy<TOther>(sampler : Emitter<TOther>) : Emitter<Tuple2<T, TOther>>
    return new Emitter(function(stream) {
      var _0 : Null<T> = null,
          _1 : Null<TOther> = null;
      stream.addCleanUp(function() {
        _0 = null;
        _1 = null;
      });
      function pulse() {
        if(null == _0 || null == _1)
          return;
        stream.pulse(new Tuple2(_0, _1));
      }
      init(new Stream(function(r) switch r {
        case Pulse(v):
          _0 = v;
        case Failure(e):  stream.fail(e);
        case End(true):   stream.cancel();
        case End(false):  stream.end();
      }));
      sampler.init(new Stream(function(r) switch r {
        case Pulse(v):
          _1 = v;
          pulse();
        case Failure(e):  stream.fail(e);
        case End(true):   stream.cancel();
        case End(false):  stream.end();
      }));
    });

  public function window(size : Int, ?emitWithLess = false) : Emitter<Array<T>>
    return new Emitter(function(stream) {
      var buf = [];
      function pulse() {
        if(buf.length > size)
          buf.shift();
        if(buf.length == size || emitWithLess)
          stream.pulse(buf.copy());
      }

      init(new Stream(function(r) switch r {
        case Pulse(v):
          buf.push(v);
          pulse();
        case Failure(e):  stream.fail(e);
        case End(true):   stream.cancel();
        case End(false):  stream.end();
      }));
    });

  public function previous() : Emitter<T>
    return new Emitter(function(stream) {
      var value : Null<T> = null,
          first = true;
      function pulse() {
        if(first) {
          first = false;
          return;
        }
        stream.pulse(value);
      }

      init(new Stream(function(r) switch r {
        case Pulse(v):
          pulse();
          value = v;
        case Failure(e):  stream.fail(e);
        case End(true):   stream.cancel();
        case End(false):  stream.end();
      }));
    });
}

class EmitterStrings {
  public static function toBool(emitter : Emitter<String>) : Emitter<Bool>
    return emitter
      .mapValue(function(s) return s != null && s != "");
}

class EmitterInts {
  public static function toBool(emitter : Emitter<Int>) : Emitter<Bool>
    return emitter
      .mapValue(function(i) return i != 0);
}

class EmitterOptions {
  public static function filterOption<T>(emitter : Emitter<Option<T>>) : Emitter<T>
    return emitter
      .filterValue(function(opt) return opt.toBool())
      .mapValue(function(opt) return opt.toValue());

  public static function toValue<T>(emitter : Emitter<Option<T>>) : Emitter<Null<T>>
    return emitter
      .mapValue(function(opt) return opt.toValue());

  public static function toBool<T>(emitter : Emitter<Option<T>>) : Emitter<Bool>
    return emitter
      .mapValue(function(opt) return opt.toBool());
}

class Emitters {
  public static function skipNull<T>(emitter : Emitter<Null<T>>) : Emitter<T>
    return emitter
      .filterValue(function(value) return null != value);
}

class EmitterBools {
  public static function negate(emitter : Emitter<Bool>)
    return emitter.mapValue(function(v) return !v);
}

@:access(thx.stream.Emitter)
class EmitterEmitters {
  public static function flatMap<T>(emitter : Emitter<Array<T>>) : Emitter<T>
    return new Emitter(function(stream) {
      emitter.init(new Stream(function(r : StreamValue<Array<T>>) {
        switch r {
        case Pulse(arr):   arr.map(stream.pulse);
        case Failure(e):   stream.fail(e);
        case End(true):    stream.cancel();
        case End(false):   stream.end();
      }}));
    });
}

class EmitterValues {
  public static function left<TLeft, TRight>(emitter : Emitter<Tuple2<TLeft, TRight>>) : Emitter<TLeft>
    return emitter.mapValue(function(v) return v._0);

  public static function right<TLeft, TRight>(emitter : Emitter<Tuple2<TLeft, TRight>>) : Emitter<TRight>
    return emitter.mapValue(function(v) return v._1);
}