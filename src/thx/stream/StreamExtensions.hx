package thx.stream;

using thx.promise.Promise;
using thx.Nil;
using thx.Tuple;
using thx.Unit;

class StreamExtensions {
  public static function max<T>(stream: Stream<T>, maxf: T -> T -> T): Stream<T> {
    return throw new thx.error.AbstractMethod();
  }

  public static function min<T>(stream: Stream<T>, minf: T -> T -> T): Stream<T> {
    return throw new thx.error.AbstractMethod();
  }

  public static function withIndex<T>(stream: Stream<T>, ?start: Int = 0): Stream<Tuple<Int, T>>
    return stream.map(function(v) return Tuple.of(start++, v));
}

class StreamUnitExtensions {
  public static function withIndex(stream: Stream<Unit>, ?start: Int = 0): Stream<Int>
    return stream.map(function(_) return start++);
}

class StreamNilExtensions {
  public static function withIndex(stream: Stream<Nil>, ?start: Int = 0): Stream<Int>
    return stream.map(function(_) return start++);
}

class ArrayStreamExtensions {
  public static function toStream<T>(a: Array<T>): Stream<T> {
    return throw new thx.error.AbstractMethod();
  }

  public static function flatten<T>(stream: Stream<Array<T>>): Stream<T> {
    return throw new thx.error.AbstractMethod();
  }
}

class PromiseArrayStreamExtensions {
  public static function toStream<T>(p: Promise<Array<T>>): Stream<T> {
    return throw new thx.error.AbstractMethod();
  }
}

class PromiseStreamExtensions {
  public static function toStream<T>(p: Promise<T>): Stream<T> {
    return throw new thx.error.AbstractMethod();
  }

  public static function flatten<T>(stream: Stream<Promise<T>>): Stream<T> {
    return throw new thx.error.AbstractMethod();
  }
/*

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
*/
}

/*
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
*/
