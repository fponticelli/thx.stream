package thx.stream;

import thx.Error;
using thx.stream.Observer;
import thx.stream.Process;
import haxe.ds.Option;
using thx.Functions;
using thx.Arrays;
using thx.Unit;
using thx.promise.Future;
using thx.promise.Promise;
#if (js || flash)
import thx.Timer;
#end

class Stream<T> {
  // constructors
  public static function value<T>(value: T): Stream<T>
    return create(function(o) {
      o.next(value);
      o.done();
    });
  public static function empty<T>(): Stream<T>
    return create(function(o) o.done());
  public static function error<T>(err: Error): Stream<T>
    return create(function(o) o.error(err));
  public static function fail<T>(msg: String, ?pos: haxe.PosInfos): Stream<T>
    return error(new Error(msg, pos));
  public static function values<T>(values: ReadonlyArray<T>): Stream<T>
    return create(function(o) {
      values.each(o.next);
      o.done();
    });
  public static function iterator<T>(values: Iterator<T>): Stream<T>
    return create(function(o) {
      for(v in values) o.next(v);
      o.done();
    });

  public static function create<T>(init: Observer<T> -> Void): Stream<T>
    return cancellable(function(o, _) {
      init(o);
      return function() {};
    });

  // public static function observe<T>(observer: Observer<T>): Stream<T> {
  //
  // }

  public static function cancellable<T>(init: Observer<T> -> ((Void -> Void) -> Void) -> Void): Stream<T>
    return new Stream(function(handler) {
      var o = new ObserverF(handler),
          cancel = Functions.noop;

      function addCancel(newcancel: Void -> Void) {
        cancel = cancel.join(newcancel);
      }

      try {
        init(o, addCancel);
      } catch(e: Dynamic) {
        o.error(thx.Error.fromDynamic(e));
      }
      return cancel;
    });

  // async
#if (js || flash)
  public static function repeat(ms: Int): Stream<Unit>
    return repeatValue(ms, Unit.unit);

  public static function repeatValue<T>(ms: Int, value: T): Stream<T>
    return poll(ms, function() return value);

  public static function poll<T>(ms: Int, f: Void -> T): Stream<T>
    return Stream.cancellable(function(o, addCancel) {
      addCancel(Timer.repeat(function() o.next(f()), ms));
    });

  public static function delay(ms: Int): Stream<Unit>
    return delayValue(ms, Unit.unit);

  public static function delayValue<T>(ms: Int, value: T): Stream<T>
    return Stream.cancellable(function(o, addCancel) {
      addCancel(
        Timer.delay(function() {
          o.next(value);
          o.done();
        }, ms)
      );
    });

  public static function frame(): Stream<Float>
    return Stream.cancellable(function(o, addCancel) {
      addCancel(Timer.frame(o.next));
    });
#end

  var init: (Message<T> -> Void) -> (Void -> Void);
  public function new(init: (Message<T> -> Void) -> (Void -> Void))
    this.init = function(handler) {
      var tryCancel = false,
          cancel = null;
      cancel = init(function(msg) {
        handler(msg);
        switch msg {
          case Done | Error(_):
            if(null != cancel) {
              // asynchronous, just shut it down
              cancel();
            } else {
              // synchronous, cancel is not available yet
              tryCancel = true;
            }
          case _:
        }
      });
      // stream completed synchronously, needs to clean-up
      if(tryCancel) {
        cancel();
      }
      return cancel;
    };

  // process methods
  public function message(handler: Message<T> -> Void): Process<T>
    return new Process(handler, init);
  public function next(handler: T -> Void): Process<T>
    return new Process(Process.nextAsMessageHandler(handler), init);
  public function failure(handler: Error -> Void): Process<T>
    return new Process(Process.errorAsMessageHandler(handler), init);
  public function done(handler: Void -> Void): Process<T>
    return new Process(Process.doneAsMessageHandler(handler), init);
  public function always(handler: Void -> Void): Process<T>
    return new Process(Process.alwaysAsMessageHandler(handler), init);

  // debug
  public function log(?prefix: String, ?pos: haxe.PosInfos): Stream<T> {
    if(null == prefix)
      prefix = "";
    else
      prefix += ": ";
    return map(function(v: T) {
      haxe.Log.trace('${prefix}${v}', pos);
      return v;
    });
  }

  public function logMessage(?prefix: String, ?pos: haxe.PosInfos): Stream<T>
    return Stream.create(function(o) {
      if(null == prefix)
        prefix = "";
      else
        prefix += ": ";
      message(function(msg: Message<T>) {
        haxe.Log.trace('${prefix}${Std.string(msg)}', pos);
        o.message(msg);
      }).run();
    });

  // selection
  public function filter(predicate: T -> Bool)
    return filterFuture(function(v) return Future.value(predicate(v)));

  public function filterFuture(predicate: T -> Future<Bool>)
    return filterPromise(function(v) return Promise.create(function(resolve, _) predicate(v).then(resolve)));

  public function filterPromise(predicate: T -> Promise<Bool>)
    return Stream.create(function(o) {
      message(function(msg) switch msg {
        case Next(v):
          predicate(v)
            .success(function(b) if(b) o.next(v))
            .failure(o.error);
        case Error(err):
          o.error(err);
        case Done:
          o.done();
      }).run();
    });

  public function filterMap<B>(predicate: T -> Option<B>): Stream<B>
    return filterMapFuture(function(v) return Future.value(predicate(v)));

  public function filterMapFuture<B>(predicate: T -> Future<Option<B>>): Stream<B>
    return filterMapPromise(function(v) return Promise.create(function(resolve, _) predicate(v).then(resolve)));

  public function filterMapPromise<B>(predicate: T -> Promise<Option<B>>): Stream<B>
    return Stream.create(function(o) {
      message(function(msg) switch msg {
        case Next(v):
          predicate(v)
            .success(function(b) switch b {
              case Some(v): o.next(v);
              case _:
            })
            .failure(o.error);
        case Error(err):
          o.error(err);
        case Done:
          o.done();
      }).run();
    });

  public function first()
    return take(1);

  public function sampledBy<B>(other: Stream<B>): Stream<Tuple<T, B>>
    return Stream.create(function(o) {
      var left = None,
          leftDone = false;
      message(function(msg) switch msg {
        case Next(l):
          left = Some(l);
        case Error(err):
          o.error(err);
        case Done:
          leftDone = true;
      }).run();
      other.message(function(msg) switch [msg, left] {
        case [Next(r), Some(l)]:
          o.next(Tuple.of(l, r));
          left = None;
        case [Next(_), None] if(leftDone):
          o.done();
        case [Next(_), _]:

        case [Error(err), _]:
          o.error(err);
        case [Done, _]:
          o.done();
      }).run();
    });

  public function samplerOf<B>(other: Stream<B>): Stream<Tuple<B, T>>
    return other.sampledBy(this);

  public function skip(qt: Int) {
    if(qt < 0)
      qt = 0;
    return Stream.create(function(o) {
      var counter = 0;
      message(function(msg) switch msg {
        case Next(v) if(counter++ >= qt):
          o.next(v);
        case Next(_):
        case Error(err):
          o.error(err);
        case Done:
          o.done();
      }).run();
    });
  }

  public function skipFirst()
    return skip(1);

  public function skipFromEnd(qt: Int) {
    if(qt < 0)
      qt = 0;
    return Stream.create(function(o) {
      var buffer = [];
      message(function(msg) switch msg {
        case Next(v):
          buffer.push(v);
          if(buffer.length == qt + 1)
            o.next(buffer.shift());
        case Error(err):
          o.error(err);
        case Done:
          o.done();
      }).run();
    });
  }

  public function skipLast()
    return skipFromEnd(1);

  public function skipUntil(predicate : T -> Bool): Stream<T>
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

  public function take(qt: Int) {
    if(qt < 0)
      qt = 0;
    return Stream.create(function(o) {
      var counter = 0;
      if(qt == counter) {
        o.done();
        return;
      }

      message(function(msg) switch msg {
          case Next(v):
            o.next(v);
            if(++counter == qt)
              o.done();
          case Error(err):
            o.error(err);
          case Done:
            o.done();
        }).run();
      });
  }

  public function takeAt(index: Int) {
    if(index < 0)
      index = 0;
    return Stream.create(function(o) {
      var counter = 0;
      message(function(msg) switch msg {
          case Next(v) if(counter++ == index):
            o.next(v);
            o.done();
          case Next(_):

          case Error(err):
            o.error(err);
          case Done:
            o.done();
        }).run();
      });
  }

  public function takeUntil(predicate : T -> Bool): Stream<T>
    return filter((function() {
      var flag = true;
      return function(v) {
        if(flag && predicate(v))
          return true;
        return flag = false;
      };
    }()));

  public function comp(compare: T -> T -> Bool): Stream<T>
    return Stream.create(function(o) {
      var curmin = None;
      message(function(msg) switch [msg, curmin] {
        case [Next(value), None]:
          curmin = Some(value);
          o.next(value);
        case [Next(value), Some(min)] if(compare(value, min)):
          curmin = Some(value);
          o.next(value);
        case [Next(_), _]:
        case [Error(err), _]:
          o.error(err);
        case [Done, _]:
          o.done();
      }).run();
    });

  public function distinct(?equality: T -> T -> Bool): Stream<T> {
    if(null == equality) equality = Functions.equality;
    return comp(function(a, b) return !equality(a, b));
  }

  public function unique(set: thx.Set<T>): Stream<T> {
    return filter(function(v) {
      return if(set.exists(v)) {
        false;
      } else {
        set.add(v);
        true;
      }
    });
  }

  public function last()
    return Stream.create(function(o) {
      var last = None;
      message(function(msg) switch [msg, last] {
        case [Next(v), _]:
          last = Some(v);
        case [Error(err), _]:
          o.error(err);
        case [Done, None]:
          o.done();
        case [Done, Some(v)]:
          o.next(v);
          o.done();
      }).run();
    });

  public function slidingWindow(minSize: Int, maxSize: Int): Stream<ReadonlyArray<T>>
    return Stream.create(function(o) {
      var acc = [];
      message(function(msg) switch msg {
        case Next(v):
          acc.push(v);
          if(acc.length == maxSize + 1)
            acc.shift();
          if(acc.length >= minSize)
            o.next(acc.copy());
        case Error(err):
          o.error(err);
        case Done:
          o.done();
      }).run();
    });

  public function window(size: Int): Stream<ReadonlyArray<T>>
    return Stream.create(function(o) {
      var acc = [];
      message(function(msg) switch msg {
        case Next(v):
          acc.push(v);
          if(acc.length == size) {
            o.next(acc);
            acc = [];
          }
        case Error(err):
          o.error(err);
        case Done:
          o.done();
      }).run();
    });

  // transforms
  public function flatMap<B>(handler: T -> Stream<B>): Stream<B>
    return Stream.create(function(o) {
      message(function(msg) switch msg {
        case Next(v):
          handler(v)
            .next(o.next)
            .error(o.error)
            // don't pass Done from the sub-stream
            .run();
        case Error(err):
          o.error(err);
        case Done:
          o.done();
      }).run();
    });

  public function map<B>(handler: T -> B): Stream<B>
    return flatMap(function(v) return Stream.value(handler(v)));

  public function effect(handler: T -> Void): Stream<T>
    return map(function(v) {
      handler(v);
      return v;
    });

  public function reduce<Acc>(handler: Acc -> T -> Acc, acc: Acc): Stream<Acc>
    return map(function(v) return acc = handler(acc, v));

  public function scan<Acc>(acc: Acc, handler: Acc -> T -> Acc): Stream<Acc>
    return reduce(handler, acc);

  public function fold(handler: T -> T -> T): Stream<T>
    return Stream.create(function(o) {
      var acc = None;
      message(function(msg) switch [msg, acc] {
        case [Next(value), None]:
          acc = Some(value);
          o.next(value);
        case [Next(b), Some(a)]:
          var x = handler(a, b);
          acc = Some(x);
          o.next(x);
        case [Error(err), _]:
          o.error(err);
        case [Done, _]:
          o.done();
      }).run();
    });

  public function collect(): Stream<Array<T>>
    return reduce(function(acc: Array<T>, v: T) return acc.concat([v]), []);

  public function collectAll(): Stream<Array<T>>
    return collect().last();

  // combine streams
  public function concat(other: Stream<T>): Stream<T>
    return Stream.create(function(o) {
      message(function(msg) switch msg {
        case Next(v):
          o.next(v);
        case Error(err):
          o.error(err);
        case Done:
          other.message(o.message).run();
      }).run();
    });

  public function merge(other: Stream<T>): Stream<T>
    return Stream.create(function(o) {
      message(o.message).run();
      other.message(o.message).run();
    });

  public function appendTo(other: Stream<T>): Stream<T>
    return other.concat(this);

  public function pair<B>(other: Stream<B>): Stream<Tuple<T, B>>
    return Stream.create(function(o) {
      var left  = None,
          right = None;
      message(function(msg) switch [msg, right] {
        case [Next(a), Some(b)]:
          left = Some(a);
          o.next(Tuple.of(a, b));
        case [Next(a), _]:
          left = Some(a);
        case [Error(err), _]:
          o.error(err);
        case [Done, _]:
          o.done();
      }).run();

      other.message(function(msg) switch [msg, left] {
        case [Next(b), Some(a)]:
          right = Some(b);
          o.next(Tuple.of(a, b));
        case [Next(b), _]:
          right = Some(b);
        case [Error(err), _]:
          o.error(err);
        case [Done, _]:
          o.done();
      }).run();
    });

  public function alternate(other: Stream<T>): Stream<T>
    return Stream.create(function(o){
      var left  = [],
          ldone = false,
          right = [],
          rdone = false,
          pickLeft = true;
      function emit() {
        var emitted = false;
        do {
          emitted = false;
          if(pickLeft && left.length > 0) {
            pickLeft = false;
            emitted = true;
            o.next(left.shift());
          }
          if(!pickLeft && right.length > 0 && !pickLeft) {
            pickLeft = true;
            emitted = true;
            o.next(right.shift());
          }
        } while(emitted);
      }
      message(function(msg) switch msg {
        case Next(l):
          left.push(l);
          emit();
          if(rdone && right.length == 0)
            o.done();
        case Error(err):
          o.error(err);
        case Done:
          if(rdone)
            o.done();
          else
            ldone = true;
      }).run();
      other.message(function(msg) switch msg {
        case Next(r):
          right.push(r);
          emit();
          if(ldone && left.length == 0 && pickLeft)
            o.done();
        case Error(err):
          o.error(err);
        case Done:
          if(ldone)
            o.done();
          else
            rdone = true;
      }).run();
    });

  public function zip<B>(other: Stream<B>): Stream<Tuple<T, B>>
    return Stream.create(function(o){
      var left  = [],
          ldone = false,
          right = [],
          rdone = false;
      function emit() {
        while(left.length > 0 && right.length > 0) {
          o.next(Tuple.of(left.shift(), right.shift()));
        }
      }
      message(function(msg) switch msg {
        case Next(l):
          left.push(l);
          emit();
          if(rdone && right.length == 0)
            o.done();
        case Error(err):
          o.error(err);
        case Done:
          if(rdone)
            o.done();
          else
            ldone = true;
      }).run();
      other.message(function(msg) switch msg {
        case Next(r):
          right.push(r);
          emit();
          if(ldone && left.length == 0)
            o.done();
        case Error(err):
          o.error(err);
        case Done:
          if(ldone)
            o.done();
          else
            rdone = true;
      }).run();
    });

  // async
#if (js || flash)
  public function delayed(ms: Int): Stream<T>
    return delay(ms).flatMap(function(_) return this);

  public function spaced(ms: Int): Stream<T>
    return Stream.create(function(o) {
      var start = Timer.time(),
          buffer = [],
          scheduled = false,
          isDone = false;
      function emit() {
        // if(scheduled) return;
        var now  = Timer.time(),
            span = now - start;
        start = now;
        scheduled = false;
        if(span >= ms) {
          o.next(buffer.shift());
          if(isDone && buffer.length == 0)
            o.done();
        }
        if(buffer.length > 0) {
          scheduled = true;
          Timer.delay(emit, ms);
        }
      }
      message(function(msg) switch msg {
        case Next(v):
          buffer.push(v);
          if(!scheduled)
            emit();
        case Error(err):
          o.error(err);
        case Done if(buffer.length == 0):
          o.done();
        case Done:
          isDone = true;
      }).run();
    });

    public function debounce(ms: Int)
      return StreamExtensions.TupleStreamExtensions.left(sampledBy(Stream.repeat(ms)));
#end
}
