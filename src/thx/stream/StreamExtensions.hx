package thx.stream;

using thx.promise.Promise;
using thx.Nil;
using thx.Options;
using thx.Tuple;
using thx.Unit;
using thx.stream.Observer;
import haxe.ds.Option;
import haxe.ds.Either;

class StreamExtensions {
  public static function count<T>(stream: Stream<T>): Stream<Int>
    return TupleStreamExtensions.left(withIndex(stream, 1));

  public static function flatten<T>(stream: Stream<Stream<T>>): Stream<T>
    return stream.flatMap(function(v) return v);

  public static function toOption<T>(stream: Stream<T>): Stream<Option<T>>
    return stream.map(function(v) return null == v ? None: Some(v));

  public static function toNil<T>(stream: Stream<T>): Stream<Nil>
    return stream.map(function(_) return Nil.nil);

  public static function toTrue<T>(stream: Stream<T>): Stream<Bool>
    return stream.map(function(_) return true);

  public static function toFalse<T>(stream: Stream<T>): Stream<Bool>
    return stream.map(function(_) return false);

  public static function toValue<A, B>(stream: Stream<A>, value: B): Stream<B>
    return stream.map(function(_) return value);

  public static function withIndex<T>(stream: Stream<T>, ?start: Int = 0): Stream<Tuple<Int, T>>
    return stream.map(function(v) return Tuple.of(start++, v));

  public static function withTimestamp<T>(stream: Stream<T>, ?start: Int = 0): Stream<Tuple<Float, T>>
    return stream.map(function(v) return Tuple.of(thx.Timer.time(), v));

  public static function nil<T>(stream: Stream<T>): Stream<Nil>
    return stream.map(function(_) return Nil.nil);

  public static function notNull<T>(stream: Stream<Null<T>>): Stream<T>
    return stream.filter(function(v) return v != null);

  public static function mapTo<T, TIn>(stream: Stream<TIn>, const: T): Stream<T>
    return stream.map(function(_) return const);

  public static function startWith<T>(stream: Stream<T>, const: T): Stream<T>
    return Stream.value(const).concat(stream);
}

class UnitStreamExtensions {
  public static function withIndex(stream: Stream<Unit>, ?start: Int = 0): Stream<Int>
    return stream.map(function(_) return start++);
}

class NilStreamExtensions {
  public static function withIndex(stream: Stream<Nil>, ?start: Int = 0): Stream<Int>
    return stream.map(function(_) return start++);
}

class StringStreamExtensions {
  public static function uniqueString(stream: Stream<String>): Stream<String>
    return stream.unique(Set.createString());

  public static function notEmpty(stream: Stream<String>): Stream<String>
    return stream.filter(function(v) return v != null && v != "");

  public static function match(stream: Stream<String>, pattern: EReg): Stream<String>
    return stream.filter(function(s) return pattern.match(s));

  public static function toBool(stream: Stream<String>): Stream<Bool>
    return stream.map(function(s) return s != null && s != "");

  public static function truthy(stream: Stream<String>): Stream<String>
    return stream.filter(function(s) return s != null && s != "");

  public static function falsy(stream: Stream<String>): Stream<String>
    return stream.filter(function(s) return s == null || s == "");

  public static function join(stream: Stream<String>, sep: String): Stream<String>
    return stream.reduce(function(acc, v) return acc + sep + v, "");
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

  public static function greaterThan(stream: Stream<Float>, x: Float): Stream<Float>
    return stream.filter(function(v) return v > x);

  public static function greaterThanOrEqualTo(stream: Stream<Float>, x: Float): Stream<Float>
    return stream.filter(function(v) return v >= x);

  public static function inRange(stream: Stream<Float>, min: Float, max: Float): Stream<Float>
    return stream.filter(function(v) return v <= max && v >= min);

  public static function insideRange(stream: Stream<Float>, min: Float, max: Float): Stream<Float>
    return stream.filter(function(v) return v < max && v > min);

  public static function lessThan(stream: Stream<Float>, x: Float): Stream<Float>
    return stream.filter(function(v) return v < x);

  public static function lessThanOrEqualTo(stream: Stream<Float>, x: Float): Stream<Float>
    return stream.filter(function(v) return v <= x);
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

  public static function greaterThan(stream: Stream<Int>, x: Int): Stream<Int>
    return stream.filter(function(v) return v > x);

  public static function greaterThanOrEqualTo(stream: Stream<Int>, x: Int): Stream<Int>
    return stream.filter(function(v) return v >= x);

  public static function inRange(stream: Stream<Int>, min: Int, max: Int): Stream<Int>
    return stream.filter(function(v) return v <= max && v >= min);

  public static function insideRange(stream: Stream<Int>, min: Int, max: Int): Stream<Int>
    return stream.filter(function(v) return v < max && v > min);

  public static function lessThan(stream: Stream<Int>, x: Int): Stream<Int>
    return stream.filter(function(v) return v < x);

  public static function lessThanOrEqualTo(stream: Stream<Int>, x: Int): Stream<Int>
    return stream.filter(function(v) return v <= x);

  public static function toBool(stream: Stream<Int>): Stream<Bool>
    return stream.map(function(i) return i != 0);
}

class BoolStreamExtensions {
  public static function keepTrue(stream: Stream<Bool>): Stream<Bool>
    return stream.filter(function(v) return v);

  public static function negate(stream: Stream<Bool>): Stream<Bool>
    return stream.map(function(v) return !v);
}

class OptionStreamExtensions {
  public static function filterOption<T>(stream: Stream<Option<T>>): Stream<T>
    return stream.filterMap(function(v) return v);

  public static function toBool<T>(stream: Stream<Option<T>>): Stream<Bool>
    return stream.map(function(opt) return opt.toBool());

  public static function toValue<T>(stream: Stream<Option<T>>): Stream<Null<T>>
    return stream.map(function(opt) return opt.get());
}

class TupleStreamExtensions {
  public static function left<A, B>(stream: Stream<Tuple<A, B>>): Stream<A>
    return stream.map(function(t) return t._0);
  public static function right<A, B>(stream: Stream<Tuple<A, B>>): Stream<B>
    return stream.map(function(t) return t._1);
}

class ArrayStreamExtensions {
  public static function toStream<T>(a: Array<T>): Stream<T>
    return Stream.values(a);

  public static function flatten<T>(stream: Stream<Array<T>>): Stream<T>
    return stream.flatMap(function(v) return Stream.values(v));
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
}

class EitherStreamExtensions {
  public static function left<A, B>(stream: Stream<Either<A, B>>): Stream<A>
    return stream.filterMap(function(e) return switch e {
      case Left(v): Some(v);
      case Right(_): None;
    });
  public static function right<A, B>(stream: Stream<Either<A, B>>): Stream<B>
    return stream.filterMap(function(e) return switch e {
      case Left(_): None;
      case Right(v): Some(v);
    });
}
