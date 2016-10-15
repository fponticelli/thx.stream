package thx.stream;

import thx.Error;
using thx.Functions;

class Process<T> {
  var handler: Message<T> -> Void;
  var init: (Message<T> -> Void) -> (Void -> Void);
  public function new(handler: Message<T> -> Void, init: (Message<T> -> Void) -> (Void -> Void)) {
    this.handler = Observer.wrapHandler(handler);
    this.init = init;
  }

  public function message(handler: Message<T> -> Void): Process<T>
    return new Process(this.handler.join(handler), init);
  public function next(handler: T -> Void): Process<T>
    return new Process(this.handler.join(nextAsMessageHandler(handler)), init);
  public function error(handler: Error -> Void): Process<T>
    return new Process(this.handler.join(errorAsMessageHandler(handler)), init);
  public function done(handler: Void -> Void): Process<T>
    return new Process(this.handler.join(doneAsMessageHandler(handler)), init);
  public function always(handler: Void -> Void): Process<T>
    return new Process(this.handler.join(alwaysAsMessageHandler(handler)), init);

  public function run()
    init(handler);

  public static function nextAsMessageHandler<T>(handler: T -> Void)
    return function(m: Message<T>) switch m {
      case Next(v): handler(v);
      case _:
    };

  public static function errorAsMessageHandler<T>(handler: Error -> Void)
    return function(m: Message<T>) switch m {
      case Error(err): handler(err);
      case _:
    };

  public static function doneAsMessageHandler<T>(handler: Void -> Void)
    return function(m: Message<T>) switch m {
      case Done: handler();
      case _:
    };

  public static function alwaysAsMessageHandler<T>(handler: Void -> Void)
    return function(m: Message<T>) switch m {
      case Done | Error(_): handler();
      case _:
    };
}
