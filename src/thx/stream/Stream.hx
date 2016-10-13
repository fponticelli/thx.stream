package thx.stream;

import thx.Error;
import thx.stream.Process;
import haxe.ds.Option;
using thx.Functions;
using thx.Arrays;
using thx.Unit;
#if (js || flash)
import thx.Timer;
#end

class Stream<T> {
  // constructors
  public static function ofValue<T>(value: T): Stream<T>
    return create(function(o) {
      o.next(value);
      o.done();
    });
  public static function empty<T>(): Stream<T>
    return create(function(o) {
      o.done();
    });
  public static function ofValues<T>(values: ReadonlyArray<T>): Stream<T>
    return create(function(o) {
      values.each(o.next);
      o.done();
    });
  public static function ofIterator<T>(values: Iterator<T>): Stream<T>
    return create(function(o) {
      for(v in values) o.next(v);
      o.done();
    });

  public static function create<T>(init: Observer<T> -> Void): Stream<T>
    return cancellable(function(o, _) {
      init(o);
      return function() {};
    });

  public static function cancellable<T>(init: Observer<T> -> ((Void -> Void) -> Void) -> Void): Stream<T>
    return new Stream(function(handler) {
      var o = new Observer(handler),
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
    return Stream.cancellable(function(o, addCancel) {
      addCancel(Timer.repeat(o.next.bind(Unit.unit), ms));
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
  public function error(handler: Error -> Void): Process<T>
    return new Process(Process.errorAsMessageHandler(handler), init);
  public function done(handler: Void -> Void): Process<T>
    return new Process(Process.doneAsMessageHandler(handler), init);
  public function always(handler: Void -> Void): Process<T>
    return new Process(Process.alwaysAsMessageHandler(handler), init);

  // debug
  public function log(?pos: haxe.PosInfos): Stream<T>
    return map(function(v: T) {
      haxe.Log.trace(v, pos);
      return v;
    });

  // selection
  public function filter(predicate: T -> Bool)
    return Stream.create(function(o) {
      message(function(msg) switch msg {
        case Next(v) if(predicate(v)): o.next(v);
        case Next(_):
        case Error(err): o.error(err);
        case Done: o.done();
      }).run();
    });

  public function first()
    return take(1);

  public function take(qt: Int) {
    if(qt < 0)
      qt = 0;
    return Stream.create(function(o) {
      var counter = 0;
      message(function(msg) switch msg {
          case Next(v):
            if(counter++ == qt)
              o.done();
            else
              o.next(v);
          case Error(err): o.error(err);
          case Done: o.done();
        }).run();
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
    return flatMap(function(v) return Stream.ofValue(handler(v)));

  public function reduce<Acc>(handler: Acc -> T -> Acc, acc: Acc): Stream<Acc>
    return map(function(v) return acc = handler(acc, v));

  public function fold(handler: T -> T -> T): Stream<T>
    return flatMap(function(a) {
      return flatMap(function(b) {
        return Stream.ofValue(a = handler(a, b));
      });
    });

  public function collect(): Stream<Array<T>>
    return reduce(function(acc: Array<T>, v: T) return acc.concat([v]), []);

  public function collectAll(): Stream<Array<T>>
    return collect().last();

  // combine streams
  public function concat(other: Stream<T>): Stream<T>
    return Stream.create(function(o) {
      message(function(msg) switch msg {
        case Next(v): o.next(v);
        case Error(err): o.error(err);
        case Done: other.message(o.message).run();
      }).run();
    });

  public function appendTo(other: Stream<T>): Stream<T>
    return other.concat(this);
}
