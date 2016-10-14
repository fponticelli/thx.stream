package thx.stream;

using thx.promise.Promise;
using thx.Nil;
using thx.Tuple;
using thx.Unit;
import haxe.ds.Option;

class StreamExtensions {
  public static function count<T>(stream: Stream<T>): Stream<Int>
    return TupleStreamExtensions.left(withIndex(stream, 1));

  public static function flatten<T>(stream: Stream<Stream<T>>): Stream<T>
    return stream.flatMap(function(v) return v);

  public static function toOption<T>(stream: Stream<T>): Stream<Option<T>>
    return stream.map(function(v) return null == v ? None : Some(v));

  public static function toNil<T>(stream: Stream<T>): Stream<Nil>
    return stream.map(function(_) return Nil.nil);

  public static function toTrue<T>(stream: Stream<T>): Stream<Bool>
    return stream.map(function(_) return true);

  public static function toFalse<T>(stream: Stream<T>): Stream<Bool>
    return stream.map(function(_) return false);

  public static function toValue<A, B>(stream: Stream<A>, value : B): Stream<B>
    return stream.map(function(_) return value);

  public static function withIndex<T>(stream: Stream<T>, ?start: Int = 0): Stream<Tuple<Int, T>>
    return stream.map(function(v) return Tuple.of(start++, v));

  public static function nil<T>(stream: Stream<T>): Stream<Nil>
    return stream.map(function(_) return Nil.nil);

  public static function notNull<T>(stream: Stream<Null<T>>): Stream<T>
    return stream.filter(function(v) return v != null);
}

class UnitStreamExtensions {
  public static function withIndex(stream: Stream<Unit>, ?start: Int = 0): Stream<Int>
    return stream.map(function(_) return start++);
}

class NilStreamExtensions {
  public static function withIndex(stream: Stream<Nil>, ?start: Int = 0): Stream<Int>
    return stream.map(function(_) return start++);
}

class FloatStreamExtensions {
  public static function min(stream: Stream<Float>): Stream<Float>
    return stream.comp(function(a, b) return a < b);

  public static function max(stream: Stream<Float>): Stream<Float>
    return stream.comp(function(a, b) return a > b);

  public static function sum(stream: Stream<Float>): Stream<Float>
    return stream.fold(function(a, b) return a + b);

  public static function average(stream: Stream<Float>): Stream<Float>
    return Stream.create(function(o) {
      var total = 0.0,
          count = 0;
        stream.message(function(msg) switch msg {
          case Next(value):
            total += value;
            count++;
            o.next(total / count);
          case Error(err):
            o.error(err);
          case Done:
            o.done();
        }).run();
    });
}

class StringStreamExtensions {
  public static function uniqueString(stream: Stream<String>): Stream<String>
    return stream.unique(Set.createString());

  public static function notEmpty(stream: Stream<String>): Stream<String>
    return stream.filter(function(v) return v != null && v != "");
}

class IntStreamExtensions {
  public static function uniqueInt(stream: Stream<Int>): Stream<Int>
    return stream.unique(Set.createInt());

  public static function min(stream: Stream<Int>): Stream<Int>
    return stream.comp(function(a, b) return a < b);

  public static function max(stream: Stream<Int>): Stream<Int>
    return stream.comp(function(a, b) return a > b);

  public static function sum(stream: Stream<Int>): Stream<Int>
    return stream.fold(function(a, b) return a + b);

  public static function average(stream: Stream<Int>): Stream<Float>
    return FloatStreamExtensions.average(cast stream); // TODO do I really need to map?
}

class OptionStreamExtensions {
  public static function filterOption<T>(stream: Stream<Option<T>>): Stream<T>
    return stream
      .filter(function(o) return switch o {
        case Some(_): true;
        case None: false;
      })
      .map(function(o) return switch o {
        case Some(v): v;
        case None: throw new thx.Error('should never happen');
      });
}

class TupleStreamExtensions {
  public static function left<A, B>(stream: Stream<Tuple<A, B>>): Stream<A>
    return stream.map(function(t) return t._0);
  public static function right<A, B>(stream: Stream<Tuple<A, B>>): Stream<B>
    return stream.map(function(t) return t._1);
}

class ArrayStreamExtensions {
  public static function toStream<T>(a: Array<T>): Stream<T>
    return Stream.ofValues(a);

  public static function flatten<T>(stream: Stream<Array<T>>): Stream<T>
    return stream.flatMap(function(v) return Stream.ofValues(v));
}

class PromiseArrayStreamExtensions {
  public static function toStream<T>(p: Promise<Array<T>>): Stream<T>
    return ArrayStreamExtensions.flatten(PromiseStreamExtensions.toStream(p));
}

class PromiseStreamExtensions {
  public static function toStream<T>(pr: Promise<T>): Stream<T>
    return Stream.create(function(o) {
      pr.success(function(v) { o.next(v); o.done(); })
        .failure(o.error);
    });

  public static function flatten<T>(stream: Stream<Promise<T>>): Stream<T>
    return stream.flatMap(function(p) return PromiseStreamExtensions.toStream(p));
/*

  public static function filterFuture(f : T -> Future<Bool>) : Emitter<T>
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

  public static function filterPromise(f : T -> Promise<Bool>) : Emitter<T>
    return filterFuture(function(v) {
      return Future.create(function(resolve) {
         f(v)
          .success(resolve)
          .throwFailure();
      });
    });

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

  public static function join(emitter : Emitter<String>, sep : String) : Emitter<String>
    return emitter.reduce("", function(acc, v) return acc + sep + v);
}

class EmitterInts {
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
