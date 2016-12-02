package thx.stream;

import thx.Error;
using thx.Functions;

class SubjectF<T> implements Subject<T> {
  var handler: Message<T> -> Void;
  public function new(handler: Message<T> -> Void) {
    this.handler = handler;
  }

  public function message(msg: Message<T>): Subject<T> {
    handler(msg);
    return this;
  }
}

interface Subject<T> {
  public function message(msg: Message<T>): Subject<T>;
}

class Subjects {
  inline public static function next<T>(subject: Subject<T>, v: T): Subject<T>
    return subject.message(Next(v));
  inline public static function error<T>(subject: Subject<T>, err: Error): Subject<T>
    return subject.message(Error(err));
  inline public static function done<T>(subject: Subject<T>): Subject<T>
    return subject.message(Done);

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
