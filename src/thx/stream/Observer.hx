package thx.stream;

import thx.Error;
using thx.Functions;

class ObserverF<T> implements Observer<T> {
  var handler: Message<T> -> Void;
  public function new(handler: Message<T> -> Void) {
    this.handler = handler;
  }

  public function message(msg: Message<T>): Observer<T> {
    handler(msg);
    return this;
  }
}

interface Observer<T> {
  public function message(msg: Message<T>): Observer<T>;
}

class Observers {
  inline public static function next<T>(observer: Observer<T>, v: T): Observer<T>
    return observer.message(Next(v));
  inline public static function error<T>(observer: Observer<T>, err: Error): Observer<T>
    return observer.message(Error(err));
  inline public static function done<T>(observer: Observer<T>): Observer<T>
    return observer.message(Done);

  // ensure that no messages are delivered after Done or Error()
  public static function wrapHandler<T>(handler: Message<T> -> Void) {
    var terminated = false;
    return function(msg: Message<T>): Void {
      if(terminated) return;
      handler(msg);
      switch msg {
        case Error(_) | Done:
          terminated = true;
        case _:
      }
    };
  }
}
