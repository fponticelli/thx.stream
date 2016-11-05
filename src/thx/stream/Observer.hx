package thx.stream;

import thx.Error;
using thx.Functions;

class Observer<T> {
  var handler: Message<T> -> Void;
  public function new(handler: Message<T> -> Void) {
    this.handler = handler; // TODO, needed? wrapHandler(handler);
  }

  public function message(msg: Message<T>): Observer<T> {
    handler(msg);
    return this;
  }
  public function next(v: T): Observer<T>
    return message(Next(v));
  public function error(err: Error): Observer<T>
    return message(Error(err));
  public function done(): Observer<T>
    return message(Done);

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
