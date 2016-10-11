package thx.stream;

import haxe.ds.Option;
using thx.Arrays;
import thx.Nil;
using thx.Options;
using thx.Tuple;
import thx.promise.Future;
import thx.promise.Promise;
import haxe.io.Bytes;

// TODO, all async methods are borken because they don't generate a queue
class Emitter<T> {
  var init : Stream<T> -> Void;
  public function new(init : Stream<T> -> Void)
    this.init = init;

  // TRIGGER METHODS
  @:access(thx.stream.Value)
  @:access(thx.stream.Stream)
  public function feed(value : Value<T>) : IStream {
    var stream : Stream<T> = new Stream(null);
    stream.subscriber = function(r) switch r {
      case Pulse(v): value.set(v);
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

  public function sign(subscriber : StreamValue<T> -> Void) : IStream {
    var stream = new Stream(subscriber);
    init(stream);
    return stream;
  }

  public function subscribe(?pulse : T -> Void, ?end : Bool -> Void) : IStream {
    pulse = null != pulse ? pulse : function(_) {};
    end   = null != end   ? end   : function(_) {};
    var stream = new Stream(function(r) switch r {
      case Pulse(v):   pulse(v);
      case End(c):     end(c);
    });
    init(stream);
    return stream;
  }

  // TRANSFORM STREAM
  public function concat(other : Emitter<T>) : Emitter<T>
    return new Emitter(function(stream) {
      init(new Stream(function(r) switch r {
        case Pulse(v):    stream.pulse(v);
        case End(true):   stream.cancel();
        case End(false):  other.init(stream);
      }));
    });

  public function count()
    return map((function(){
        var c = 0;
        return function(_) return ++c;
      })());
#if (js || swf || java)
  public function debounce(delay : Int)
    return new Emitter(function(stream) {
      var cancel = function() {};
      stream.addCleanUp(function() cancel());
      init(new Stream(function(r : StreamValue<T>) {
        switch r {
          case Pulse(v):
            cancel();
            cancel = thx.Timer.delay(stream.pulse.bind(v), delay);
          case End(true):  stream.cancel();
          case End(false): thx.Timer.delay(stream.end, delay);
        }
      }));
    });

  public function delay(time : Int)
    return new Emitter(function(stream) {
      var cancel = thx.Timer.delay(function() init(stream), time);
      stream.addCleanUp(cancel);
    });
#end

  public function diff<TOut>(?init : Null<T>, f : T -> T -> TOut) : Emitter<TOut>
    return window(2, null != init).map(function(a) {
        return if(a.length == 1)
          f(init, a[0]);
        else
          f(a[0], a[1]);
      });

  public function merge(other : Emitter<T>) : Emitter<T>
    return new Emitter(function(stream : Stream<T>) {
      init(stream);
      other.init(stream);
    });

  public function previous() : Emitter<T>
    return new Emitter(function(stream : Stream<T>) {
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
        case End(true):   stream.cancel();
        case End(false):  stream.end();
      }));
    });

  public function reduce<TOut>(acc : TOut, f : TOut -> T -> TOut) : Emitter<TOut>
    return new Emitter(function(stream) {
      init(new Stream(function(r) switch r {
        case Pulse(v):
          acc = f(acc, v);
          stream.pulse(acc);
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
        case End(true):   stream.cancel();
        case End(false):  stream.end();
      }));
    });

  // TRANSFORM VALUES
  // TODO express map and filter as cases of reduce
  public function map<TOut>(f : T -> TOut) : Emitter<TOut>
    return mapFuture(function(v) return Future.value(f(v)));

  public function mapFuture<TOut>(f : T -> Future<TOut>) : Emitter<TOut>
    return new Emitter(function(stream) {
      var queue : Array<StreamValue<TOut>> = [],
          pos = 0;

      function poll() {
        while(queue[pos] != null) {
          var r = queue[pos];
          queue[pos++] = null;
          switch r {
            case Pulse(v):   stream.pulse(v);
            case End(true):  stream.cancel();
            case End(false): stream.end();
          };
        }
      }

      function resolve(r : StreamValue<T>)
        switch r {
          case Pulse(v):
            var index = queue.length;
            queue.push(null);
            f(v).then(function(o) {
              queue[index] = Pulse(o);
              poll();
            });
          case End(c):
            queue.push(End(c));
            poll();
        }

      init(new Stream(resolve));
    });

  public function mapPromise<TOut>(f : T -> Promise<TOut>) : Emitter<TOut>
    return mapFuture(function(v) {
      return Future.create(function(resolve) {
         f(v)
          .success(resolve)
          .throwFailure();
      });
    });

  public function toOption() : Emitter<Option<T>>
    return map(function(v) return null == v ? None : Some(v));
  public function toNil() : Emitter<Nil>
    return map(function(_) return nil);
  public function toTrue() : Emitter<Bool>
    return map(function(_) return true);
  public function toFalse() : Emitter<Bool>
    return map(function(_) return false);
  public function toValue<T>(value : T) : Emitter<T>
    return map(function(_) return value);

  // FILTER STREAM
  public function filter(f : T -> Bool) : Emitter<T>
    return filterFuture(function(v) return Future.value(f(v)));

  public function filterFuture(f : T -> Future<Bool>) : Emitter<T>
    return new Emitter(function(stream) {
      var queue : Array<Option<StreamValue<T>>> = [],
          pos = 0;

      function poll() {
        while(queue[pos] != null) {
          var r = queue[pos];
          queue[pos++] = null;
          switch r {
            case Some(Pulse(v)):   stream.pulse(v);
            case Some(End(true)):  stream.cancel();
            case Some(End(false)): stream.end();
            case None: //do nothing, it has been filtered out
          };
        }
      }

      function resolve(r : StreamValue<T>)
        switch r {
          case Pulse(v):
            var index = queue.length;
            queue.push(null);
            f(v).then(function(c) {
              if(c)
                queue[index] = Some(r);
              else
                queue[index] = None;
              poll();
            });
          case other:
            queue.push(Some(other));
            poll();
        }

      init(new Stream(resolve));
    });

  public function filterPromise(f : T -> Promise<Bool>) : Emitter<T>
    return filterFuture(function(v) {
      return Future.create(function(resolve) {
         f(v)
          .success(resolve)
          .throwFailure();
      });
    });

  public function first()
    return take(1);

  public function distinct(?equals : T -> T -> Bool) : Emitter<T> {
    if(null == equals)
        equals = function(a, b) return a == b;
      var last : T = null;
    return filter(function(v) {
      return if(equals(v, last))
        false;
      else {
        last = v;
        true;
      }
    });
  }

  public function last() : Emitter<T>
    return new Emitter(function(stream) {
      var last : Null<T> = null;
      init(new Stream(function(r) {
        switch r {
        case Pulse(v):   last = v;
        case End(true):  stream.cancel();
        case End(false):
          stream.pulse(last);
          stream.end();
      }}));
    });

  public function memberOf(arr : Array<T>, ?equality : T -> T -> Bool)
    return filter(function(v) return arr.contains(v, equality));

  public function notNull()
    return filter(function(v) return v != null);

  public function skip(n : Int)
    return skipUntil((function() {
      var count = 0;
      return function(_) return count++ < n;
    })());

  public function skipUntil(predicate : T -> Bool)
    return filter((function() {
      var flag = false;
      return function(v) {
        if(flag)
          return true;
        if(predicate(v))
          return false;
        return flag = true;
      };
    }()));

  public function take(count : Int) : Emitter<T>
    return takeUntil((function(counter : Int) : T -> Bool {
        return function(_ : T) : Bool return counter++ < count;
      })(0));

  public function takeAt(index : Int) : Emitter<T>
    // cast is required by C#
    return cast take(index + 1).last();

  public function takeLast(n : Int) : Emitter<T>
    return EmitterArrays.flatten(window(n).last());

  // TODO: ... have a look at those nasty instream
  public function takeUntil(f : T -> Bool) : Emitter<T>
    return new Emitter(function(stream : Stream<T>) {
      var instream : Stream<T> = null;
      instream = new Stream(function(r : StreamValue<T>) switch r {
        case Pulse(v):
          if(f(v)) {
              stream.pulse(v);
          } else {
            instream.end();
            stream.end();
          }
        case End(true):
          instream.cancel();
          stream.cancel();
        case End(false):
          instream.end();
          stream.end();
      });
      this.init(instream);
    });
  public function withValue(expected : T) : Emitter<T>
    return filter(function(v : T) return v == expected);

  // AGGREGATE
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
        case End(true):   stream.cancel();
        case End(false):  stream.end();
      }));
      other.init(new Stream(function(r) switch r {
        case Pulse(v):
          _1 = v;
          pulse();
        case End(true):   stream.cancel();
        case End(false):  stream.end();
      }));
    });

  // throttle(wait) at most once every per wait use sampleBy(Timer.repeat(Nil, wait)).left()
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
        case End(true):   stream.cancel();
        case End(false):  stream.end();
      }));
      sampler.init(new Stream(function(r) switch r {
        case Pulse(v):
          _1 = v;
          pulse();
        case End(true):   stream.cancel();
        case End(false):  stream.end();
      }));
    });

  public function samplerOf<TOther>(sampled : Emitter<TOther>) : Emitter<Tuple2<T, TOther>>
    return sampled.sampleBy(this).map(function(t) return t.flip());

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
        case End(true):   stream.cancel();
        case End(false):  stream.end();
      }));
      other.init(new Stream(function(r) switch r {
        case Pulse(v):
          _1.push(v);
          pulse();
        case End(true):   stream.cancel();
        case End(false):  stream.end();
      }));
    });

  // UTILITY
  public function audit(handler : T -> Void) : Emitter<T>
    return map(function(v) {
      handler(v);
      return v;
    });

  public function log(?prefix : String, ?posInfo : haxe.PosInfos) {
    prefix = prefix == null ? '': '${prefix}: ';
    return map(function(v) {
      haxe.Log.trace('$prefix$v', posInfo);
      return v;
    });
  }

#if (js || swf || java)
  public function split() : Tuple2<Emitter<T>, Emitter<T>> {
    var inited  = false,
        streams = [];
    function init(stream) {
      streams.push(stream);
      if(!inited) {
        inited = true;
        // the delay ensures that the second stream has the time to be implemented
        thx.Timer.immediate(function() {
          this.init(new Stream(function(r) {
            switch r {
              case Pulse(v):   for(s in streams) s.pulse(v);
              case End(true):  for(s in streams) s.cancel();
              case End(false): for(s in streams) s.end();
            };
          }));
        });
      }
    }
    return new Tuple2(new Emitter(init), new Emitter(init));
  }
#end
}

class EagerEmitter<T> extends Emitter<T> {
  var stack : Array<T>;
  var conclusion : Int;
  public function new(init : Stream<T> -> Void) {
    super(init);
    stack = [];
    conclusion = -1;
    subscribe(
      function(p) stack.push(p),
      function(c) conclusion = c ? 1 : 0
    );
  }

  override public function sign(subscriber : StreamValue<T> -> Void) : IStream {
    var stream = super.sign(subscriber);
    for(v in stack) {
      subscriber(Pulse(v));
    }
    if(conclusion >= 0)
      subscriber(End(conclusion == 1));
    return stream;
  }
}

class Emitters {
  public static function skipNull<T>(emitter : Emitter<Null<T>>) : Emitter<T>
    // cast is required by C#
    return cast emitter
      .filter(function(value) return null != value);

  public static function unique<T>(emitter : Emitter<T>) : Emitter<T>
    return emitter.filter((function() {
      var buf = [];
      return function(v) {
        return if(buf.indexOf(v) >= 0)
          false;
        else {
          buf.push(v);
          true;
        }
      };
    })());

  public static function toPromise<T>(emitter : Emitter<T>) : Promise<Array<T>>
    return Promise.create(function(resolve, reject) {
      var arr = [];
      emitter.subscribe(
        arr.push,
        function(c) {
          if(c)
            reject(new thx.Error('stream has been canceled'));
          else
            resolve(arr);
        });
    });
}

class EmitterBytes {
  public static function toPromise(emitter : Emitter<Bytes>) : Promise<Bytes>
    return Promise.create(function(resolve, reject) {
      var buf = Bytes.alloc(0);
      emitter.subscribe(
        function(b)  {
          var nbuf = Bytes.alloc(buf.length + b.length);
          nbuf.blit(0, buf, 0, buf.length);
          nbuf.blit(buf.length, b, 0, b.length);
          buf = nbuf;
        },
        function(cancel)
          if(cancel) reject(new thx.Error("Data stream has been cancelled"))
          else       resolve(buf)
      );
    });
}

class EmitterStrings {
  public static function match(emitter : Emitter<String>, pattern : EReg) : Emitter<String>
    return emitter.filter(function(s) return pattern.match(s));

  public static function toBool(emitter : Emitter<String>) : Emitter<Bool>
    return emitter.map(function(s) return s != null && s != "");

  public static function truthy(emitter : Emitter<String>) : Emitter<String>
    return emitter.filter(function(s) return s != null && s != "");

  public static function unique(emitter : Emitter<String>) : Emitter<String>
    return emitter.filter((function() {
      var buf = new Map<String, Bool>();
      return function(v) {
        return if(buf.exists(v))
          false;
        else {
          buf.set(v, true);
          true;
        }
      };
    })());

  public static function join(emitter : Emitter<String>, sep : String) : Emitter<String>
    return emitter.reduce("", function(acc, v) return acc + sep + v);

  public static function filterEmpty(emitter : Emitter<String>) : Emitter<String>
    return emitter.filter(function(v) return !thx.Strings.isEmpty(v));
}

class EmitterInts {
  public static function average(emitter : Emitter<Int>) : Emitter<Float>
    return emitter
      .map((function(){
        var sum = 0.0,
            count = 0;
        return function(v) return (sum += v) / (++count);
      })());

  public static function greaterThan(emitter : Emitter<Int>, x : Int) : Emitter<Int>
    return emitter.filter(function(v) return v > x);

  public static function greaterThanOrEqualTo(emitter : Emitter<Int>, x : Int) : Emitter<Int>
    return emitter.filter(function(v) return v >= x);

  public static function inRange(emitter : Emitter<Int>, min : Int, max : Int) : Emitter<Int>
    return emitter.filter(function(v) return v <= max && v >= min);

  public static function insideRange(emitter : Emitter<Int>, min : Int, max : Int) : Emitter<Int>
    return emitter.filter(function(v) return v < max && v > min);

  public static function lessThan(emitter : Emitter<Int>, x : Int) : Emitter<Int>
    return emitter.filter(function(v) return v < x);

  public static function lessThanOrEqualTo(emitter : Emitter<Int>, x : Int) : Emitter<Int>
    return emitter.filter(function(v) return v <= x);

  public static function max(emitter : Emitter<Int>) : Emitter<Int>
    return emitter
      .filter((function() {
        var max : Null<Int> = null;
        return function(v)
          return if(null == max || v > max) {
            max = v;
            true;
          } else {
            false;
          }
        })());

  public static function min(emitter : Emitter<Int>) : Emitter<Int>
    return emitter
      .filter((function() {
        var min : Null<Int> = null;
        return function(v)
          return if(null == min || v < min) {
            min = v;
            true;
          } else {
            false;
          }
        })());

  public static function sum(emitter : Emitter<Int>) : Emitter<Int>
    return emitter
      .map((function(){
        var value = 0;
        return function(v) return value += v;
      })());

  public static function toBool(emitter : Emitter<Int>) : Emitter<Bool>
    return emitter
      .map(function(i) return i != 0);

  public static function unique(emitter : Emitter<Int>) : Emitter<Int>
    return emitter.filter((function() {
      var buf = new Map<Int, Bool>();
      return function(v) {
        return if(buf.exists(v))
          false;
        else {
          buf.set(v, true);
          true;
        }
      };
    })());
}

class EmitterFloats {
  public static function average(emitter : Emitter<Float>) : Emitter<Float>
    return emitter
      .map((function(){
        var sum = 0.0,
            count = 0;
        return function(v) return (sum += v) / (++count);
      })());

  public static function greaterThan(emitter : Emitter<Float>, x : Float) : Emitter<Float>
    return emitter.filter(function(v) return v > x);

  public static function greaterThanOrEqualTo(emitter : Emitter<Float>, x : Float) : Emitter<Float>
    return emitter.filter(function(v) return v >= x);

  public static function inRange(emitter : Emitter<Float>, min : Float, max : Float) : Emitter<Float>
    return emitter.filter(function(v) return v <= max && v >= min);

  public static function insideRange(emitter : Emitter<Float>, min : Float, max : Float) : Emitter<Float>
    return emitter.filter(function(v) return v < max && v > min);

  public static function lessThan(emitter : Emitter<Float>, x : Float) : Emitter<Float>
    return emitter.filter(function(v) return v < x);

  public static function lessThanOrEqualTo(emitter : Emitter<Float>, x : Float) : Emitter<Float>
    return emitter.filter(function(v) return v <= x);

  public static function max(emitter : Emitter<Float>) : Emitter<Float>
    return emitter
      .filter((function() {
        var max : Float = Math.NEGATIVE_INFINITY;
        return function(v)
          return if(v > max) {
            max = v;
            true;
          } else {
            false;
          }
        })());

  public static function min(emitter : Emitter<Float>) : Emitter<Float>
    return emitter
      .filter((function() {
        var min : Float = Math.POSITIVE_INFINITY;
        return function(v)
          return if(v < min) {
            min = v;
            true;
          } else {
            false;
          }
        })());

  public static function sum(emitter : Emitter<Float>) : Emitter<Float>
    return emitter
      .map((function(){
        var sum = 0.0;
        return function(v) return sum += v;
      })());
}

class EmitterOptions {
  public static function either<T>(emitter : Emitter<Option<T>>, ?some : T -> Void, ?none : Void -> Void, ?end : Bool -> Void) {
    if(null == some) some = function(_) {};
    if(null == none) none = function() {};
    return emitter.subscribe(
        function(o : Option<T>) switch o {
          case Some(v) : some(v);
          case None: none();
        },
        end
      );
  }

  public static function filterOption<T>(emitter : Emitter<Option<T>>) : Emitter<T>
    return emitter
      .filter(function(opt) return opt.toBool())
      // cast is required by C#
      .map(function(opt) return (opt.get() : T));

  public static function toBool<T>(emitter : Emitter<Option<T>>) : Emitter<Bool>
    return emitter
      .map(function(opt) return opt.toBool());

  public static function toValue<T>(emitter : Emitter<Option<T>>) : Emitter<Null<T>>
    return emitter
      .map(function(opt) return opt.get());
}

class EmitterBools {
  public static function negate(emitter : Emitter<Bool>)
    return emitter.map(function(v) return !v);
}

@:access(thx.stream.Emitter)
class EmitterEmitters {
  // TODO: is flatMap the right name here?
  public static function flatMap<T>(emitter : Emitter<Emitter<T>>) : Emitter<T>
    return new Emitter(function(stream) {
      emitter.init(new Stream(function(r : StreamValue<Emitter<T>>) {
        switch r {
          case Pulse(em):  em.init(stream);
          case End(true):  stream.cancel();
          case End(false): stream.end();
        }}));
    });
}

@:access(thx.stream.Emitter)
class EmitterArrays {
  public static function containerOf<T>(emitter : Emitter<Array<T>>, value : T) : Emitter<Array<T>>
    return emitter.filter(function(arr) return arr.indexOf(value) >= 0);

  public static function flatten<T>(emitter : Emitter<Array<T>>) : Emitter<T>
    return new Emitter(function(stream) {
      emitter.init(new Stream(function(r : StreamValue<Array<T>>) {
        switch r {
          case Pulse(arr): arr.map(stream.pulse);
          case End(true):  stream.cancel();
          case End(false): stream.end();
        }}));
    });
}

class EmitterValues {
  public static function left<TLeft, TRight>(emitter : Emitter<Tuple2<TLeft, TRight>>) : Emitter<TLeft>
    return emitter.map(function(v) return v._0);

  public static function right<TLeft, TRight>(emitter : Emitter<Tuple2<TLeft, TRight>>) : Emitter<TRight>
    return emitter.map(function(v) return v._1);
}
