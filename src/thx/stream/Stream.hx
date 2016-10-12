package thx.stream;

import thx.Error;
using thx.Functions;
using thx.Arrays;
using thx.promise.Promise;
import thx.stream.Emitter;

class Stream<T> {
  // static constructors
  public static function ofValues<T>(v: Array<T>): Stream<T> {
    var emitter = new StreamEmitter(function(cancel) return new BufferStream(cancel, []));
    v.each(emitter.next);
    emitter.complete();
    return emitter.stream;
  }

  public static function lazy<T>(init: Emitter<T> -> Void): Stream<T> {
    return new LazyStream(init);
  }

  // basic methods
  public function on(f: StreamValue<T> -> Void): Stream<T>
    return throw new thx.error.AbstractMethod();
  public function cancel(): Void
    return throw new thx.error.AbstractMethod();

  // transform
  public function map<B>(f: T -> B): Stream<B> {
    return lazy(function(e) {
      on(function(sv) switch sv {
        case Value(v):
          e.next(f(v));
        case Error(err):
          e.error(err);
        case Done(b):
          e.done(b);
      });
    });
  }

  public function flatMap<B>(f: T -> Stream<B>): Stream<B> {
    return lazy(function(e) {
      on(function(sv) switch sv {
        case Value(v):
          f(v).on(e.send);
        case Error(err):
          e.error(err);
        case Done(b):
          e.done(b);
      });
    });
  }

  public function reduceAll<Acc>(f: Acc -> T -> Acc, acc: Acc): Stream<Acc> {
    return lazy(function(e) {
      on(function(v) switch v {
        case Value(v):
          acc = f(acc, v);
        case Done(b):
          e.next(acc);
          e.done(b);
        case Error(err):
          e.error(err);
      });
    });
  }

  public function reduce<Acc>(f: Acc -> T -> Acc, acc: Acc): Stream<Acc> {
    return throw new thx.error.AbstractMethod();
  }

  public function collectAll(): Stream<Array<T>> {
    return reduceAll(function(acc: Array<T>, v: T) {
      return acc.concat([v]);
    }, []);
  }

  public function toPromise(): Promise<Array<T>> {
    return throw new thx.error.AbstractMethod();
  }

  public function appendTo(other: Stream<T>): Stream<T> {
    return throw new thx.error.AbstractMethod();
  }

  public function followedBy(other: Stream<T>): Stream<T> {
    return throw new thx.error.AbstractMethod();
  }

  public function alternate(other: Stream<T>): Stream<T> {
    return throw new thx.error.AbstractMethod();
  }

  public function count(): Stream<Int> {
    return throw new thx.error.AbstractMethod();
  }

  public function withIndex(other: Stream<T>): Stream<Tuple<Int, T>> {
    return throw new thx.error.AbstractMethod();
  }

  public function window(minxSize: Int, maxSize: Int): Stream<Array<T>> {
    return throw new thx.error.AbstractMethod();
  }

  public function zip<B>(other: Stream<B>): Stream<Tuple<T, B>> {
    return throw new thx.error.AbstractMethod();
  }

/*
Split the chain so that `cancel()` does not propagate all the way up but only up
to the `branch()` point.
*/
  public function branch(): Stream<T> {
    return throw new thx.error.AbstractMethod();
  }
/*
public function diff<TOut>(?init : Null<T>, f : T -> T -> TOut) : Emitter<TOut>
  return window(2, null != init).map(function(a) {
      return if(a.length == 1)
        f(init, a[0]);
      else
        f(a[0], a[1]);
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
  public function filter(f : T -> Bool) : Emitter<T>
    return filterFuture(function(v) return Future.value(f(v)));

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
*/

  // time based
  public function debounce(time: Int): Stream<T> {
    return throw new thx.error.AbstractMethod();
  }
  public function delay(time: Int): Stream<T> {
    return throw new thx.error.AbstractMethod();
  }
  public function interval(time: Int): Stream<T> {
    return throw new thx.error.AbstractMethod();
  }

  // side effects
  public function onValue(f: T -> Void): Stream<T>
    return on(function(v) switch v {
      case Value(v): f(v);
      case _: // do nothing
    });
  public function onError(f: Error -> Void): Stream<T>
    return on(function(v) switch v {
      case Error(err): f(err);
      case _: // do nothing
    });
  public function onTerminated(f: Void -> Void): Stream<T>
    return on(function(v) switch v {
      case Done(_): f();
      case _: // do nothing
    });
  public function onCanceled(f: Void -> Void): Stream<T>
    return on(function(v) switch v {
      case Done(true): f();
      case _: // do nothing
    });
  public function onCompleted(f: Void -> Void): Stream<T>
    return on(function(v) switch v {
      case Done(false): f();
      case _: // do nothing
    });
}

class SubscriberStream<T> extends Stream<T> {
  var _cancel: Void -> Void;
  public function new(cancel: Void -> Void)
    this._cancel = cancel;
  public function notify(value: StreamValue<T>): Void
    throw new thx.error.AbstractMethod();
  override function cancel()
    _cancel();
}

class VolatileStream<T> extends SubscriberStream<T> {
  var f: StreamValue<T> -> Void;
  override function on(f: StreamValue<T> -> Void): Stream<T> {
    this.f = null == this.f ? f : this.f.join(f);
    return this;
  }
  override function notify(value: StreamValue<T>): Void {
    if(null != f)
      f(value);
  }
}

class LastStream<T> extends SubscriberStream<T> {
  var last: StreamValue<T> = null;
  var next: SubscriberStream<T> = null;
  var f: StreamValue<T> -> Void = null;

  public function new(cancel: Void -> Void) {
    super(cancel);
  }

  override function on(f: StreamValue<T> -> Void): Stream<T> {
    this.f = null == this.f ? f : this.f.join(f);
    next = new BufferStream(cancel, [last]);
    if(null != last)
      f(last);
    last = null;
    return next;
  }

  override function notify(v: StreamValue<T>) {
    last = v;
    if(null != f)
      f(v);
    if(null != next)
      next.notify(v);
  }
}

class BufferStream<T> extends SubscriberStream<T> {
  var acc: Array<StreamValue<T>> = [];
  var next: SubscriberStream<T> = null;
  var f: StreamValue<T> -> Void = null;

  public function new(cancel: Void -> Void, values: Array<StreamValue<T>>) {
    this.acc = values;
    super(cancel);
  }

  override function on(f: StreamValue<T> -> Void): Stream<T> {
    this.f = null == this.f ? f : this.f.join(f);
    next = new BufferStream(cancel, acc);
    for(v in acc)
      f(v);
    acc = [];
    return next;
  }

  override function notify(v: StreamValue<T>) {
    acc.push(v);
    if(null != f)
      f(v);
    if(null != next)
      next.notify(v);
  }
}

class LazyStream<T> extends Stream<T> {
  var init: Emitter<T> -> Void;
  var _cancel: Void -> Void;
  public function new(init: Emitter<T> -> Void) {
    this._cancel = function() { trace("CANCELED"); } // TODO remove trace
    this.init = init;
  }
  override function on(f: StreamValue<T> -> Void): Stream<T> {
    var emitter = new StreamEmitter(function(cancel) return new BufferStream(cancel, []));
    _cancel = _cancel.join(emitter.cancel); // compose cancel
    init(emitter);
    return emitter.stream.on(f);
  }

  override function cancel()
    _cancel();
}


/*
import thx.Timer in T;

class Timer {
  public static function arrayToSequence<T>(arr : Array<T>, delay : Int)
    return sequencei(arr.length, delay, function(i) return arr[i]);

  public static function repeat(delay : Int)
    return new Emitter(function(stream : Stream<Nil>) {
      var cancel = T.repeat(stream.pulse.bind(Nil.nil), delay);
      stream.addCleanUp(cancel);
    });

  public static function times(repetitions : Int, delay : Int)
    return repeat(delay).take(repetitions);

  public static function sequence<T>(repetitions : Int, delay : Int, build : Void -> T)
    return times(repetitions, delay).map(function(_) return build());

  public static function sequencei<T>(repetitions : Int, delay : Int, build : Int -> T)
    return sequence(repetitions, delay, {
      var i = 0;
      function() return build(i++);
    });

  public static function sequenceNil<T>(repetitions : Int, delay : Int, build : Nil -> T)
    return times(repetitions, delay).map(build);
}
*/
