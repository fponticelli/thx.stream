package thx.stream;

import thx.Error;
using thx.Functions;
using thx.Arrays;
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

  public function reduce<Acc>(f: Acc -> T -> Acc, acc: Acc): Stream<Acc> {
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

  public function collectAll(): Stream<Array<T>> {
    return reduce(function(acc: Array<T>, v: T) {
      return acc.concat([v]);
    }, []);
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
