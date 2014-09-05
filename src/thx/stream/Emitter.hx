package thx.stream;

import haxe.ds.Option;
import thx.core.Error;
import thx.core.Nil;
import thx.core.Timer in T;
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

  public function delay(time : Int)
    return new Emitter(function(stream) {
      var id = T.delay(function() init(stream), time);
      stream.addCleanUp(T.clear.bind(id));
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

/*
  public function zip<TOther>(other : Producer<TOther>) : Producer<Tuple2<T, TOther>> {
    return new Producer(function(forward : Pulse<Tuple2<T, TOther>> -> Void) {
      var ended = false,
        endA  = false,
        endB  = false,
        buffA : Array<T> = [],
        buffB : Array<TOther> = [];

      function produce() {
        if(((buffA.length == 0 && endA) || (buffB.length == 0 && endB)) && !ended) {
          buffA = null;
          buffB = null;
          ended = true;
          return forward(End);
        }
        if(buffA.length == 0 || buffB.length == 0) return;
        forward(Emit(new Tuple2(buffA.shift(), buffB.shift())));
      }

      this.feed(new Bus(
        function(value : T) {
          if(ended) return;
          buffA.push(value);
          produce();
        },
        function() {
          endA = true;
          produce();
        },
        function(error) {
          forward(Fail(error));
        }
      ));

      other.feed(new Bus(
        function(value : TOther) {
          if(ended) return;
          buffB.push(value);
          produce();
        },
        function() {
          endB = true;
          produce();
        },
        function(error) {
          forward(Fail(error));
        }
      ));
    }, endOnError);
  }

  public function blend<TOther, TOut>(other : Producer<TOther>, f : T -> TOther -> TOut) : Producer<TOut> {
    return this.zip(other).map(function(tuple) {
      return f(tuple._0, tuple._1);
    });
  }

  public function pair<TOther>(other : Producer<TOther>) : Producer<Tuple2<T, TOther>> {
    return new Producer(function(forward : Pulse<Tuple2<T, TOther>> -> Void) {
      var endA  = false,
        endB  = false,
        buffA : T = null,
        buffB : TOther = null;

      function produce() {
        if(endA && endB) {
          buffA = null;
          buffB = null;
          return forward(End);
        }
        if(buffA == null || buffB == null) return;
        forward(Emit(new Tuple2(buffA, buffB)));
      }

      this.feed(new Bus(
        function(value : T) {
          buffA = value;
          produce();
        },
        function() {
          endA = true;
          produce();
        },
        function(error) {
          forward(Fail(error));
        }
      ));

      other.feed(new Bus(
        function(value : TOther) {
          buffB = value;
          produce();
        },
        function() {
          endB = true;
          produce();
        },
        function(error) {
          forward(Fail(error));
        }
      ));

    }, endOnError);
  }

  public function distinct(?equals : T -> T -> Bool) : Producer<T> {
    if(null == equals)
      equals = function(a, b) return a == b;
    return new Producer(function(forward) {
      var last : T = null;
      this.feed(Bus.passOn(
        function(v) {
          if(equals(v, last)) return;
          last = v;
          forward(Emit(v));
        },
        forward
      ));
    }, endOnError);
  }

  public  function debounce(delay : Int) : Producer<T> {
    return new Producer(function(forward) {
      var id : TimerID = null;
      this.feed(Bus.passOn(
        function(v : T) {
          Timer.clearTimer(id);
          id = Timer.setTimeout(forward.bind(Emit(v)), delay);
        },
        forward
      ));
    }, endOnError);
  }

  public function sampleBy<TSampler>(sampler : Producer<TSampler>) : Producer<Tuple2<T, TSampler>> {
    return new Producer(function(forward : Pulse<Tuple2<T, TSampler>> -> Void) {
      var latest : T = null;
      this.feed(Bus.passOn(
        function(v) latest = v,
        forward
      ));
      sampler.feed(Bus.passOn(
        function(v) {
          // skip if this hasn't produced anything yet or has been cleared
          if(null == latest) return;
          forward(Emit(new Tuple2(latest, v)));
          latest = null;
        },
        forward
      ));
    }, endOnError);
  }

  public function keep(n : Int) : Producer<Array<T>> {
    return new Producer(function(forward) {
      var acc = [];
      this.feed(Bus.passOn(
        function(v) {
          acc.push(v);
          if(acc.length > n)
            acc.shift();
          forward(Emit(acc));
        },
        forward
      ));
    }, endOnError);
  }

  public function previous() : Producer<T> {
    return new Producer(function(forward) {
      var isFirst   = true,
        state : T = null;
      this.feed(Bus.passOn(
        function(v) {
          if(isFirst) {
            isFirst = false;
          } else {
            forward(Emit(state));
          }
          state = v;
        },
        forward
      ));
    }, endOnError);
  }
*/
// public function window(length : Int, fillBeforeEmit = false) : Emitter<T> // or unique
// public function reduce(acc : TOut, TOut -> T) : Emitter<TOut>
// public function debounce(delay : Int) : Emitter<T>
// exact pair
// public function zip<TOther>(other : Emitter<TOther>) : Emitter<Tuple<T, TOther>> // or sync
// mapFilter?
}

class EmitterStrings {
  public static function toBool(emitter : Emitter<String>) : Emitter<Bool>
    return emitter
      .mapValue(function(s) return s != null && s != "");
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