package thx.stream;

import thx.core.Error;

class Producer<T> {
  var handler : Subscriber<T> -> (Void -> Void);
  public function new(handler : Subscriber<T> -> (Void -> Void)) {
    this.handler = handler;
  }
  public function subscribe(subscriber : Subscriber<T>) : Void -> Void {
    var _cancel = handler(subscriber),
        cancel  = function() {
          _cancel();
          subscriber(End);
        };
    return function() {
      var c = cancel;
      cancel = function() {};
      c();
    }
  }

  public function register(valueHandler : T -> Void) : Void -> Void
    return subscribe(function(r) switch r {
      case Pulse(v): valueHandler(v);
      case _: // do nothing
    });

  public function take(number : Int) {
    if(number <= 0) throw '"take" argument should be a positive non zero value';
    return new Producer(function(handler) {
      var counter  = 0,
          cancel   = function() {},
          counterf = function(v) {
            handler(v);
            if(++counter == number)
              cancel();
          };
      return cancel = subscribe(counterf);
    });
  }

  public function mapValue<TOut>(transform : T -> TOut)
    return new Producer(function(handler)
      return subscribe(function(r) switch r {
        case Pulse(v): handler(Pulse(transform(v)));
        case Failure(e): handler(Failure(e));
        case End: handler(End);
      })
    );
  // map
  // filter
}

class Guardian<T> {
  var subscriber : Subscriber<T>;
  public var stream : Stream;
  public function new(subscriber : Subscriber<T>) {
    this.subscriber = subscriber;
  }
  public function listener(value : StreamValue<T>) : Void {
    subscriber(value);
    switch value {
      case End, Failure(_):
        stream.cancel();
      case _:
    }
  }
}

class Stream {
  var doCancel : Void -> Void;
  public function new(doCancel : Void -> Void) {
    this.doCancel = doCancel;
  }
  public function cancel() {
    trace('cancelling ${null != doCancel}');
    if(null != doCancel) {
      doCancel();
      doCancel = null;
    }
  }
}