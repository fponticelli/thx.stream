package thx.stream;

import utest.Assert;
import thx.stream.StreamValue;
import thx.promise.Promise;

class Asserter<T> {
  public static function create<T>(values : Array<T>, done : Void -> Void, debug = false)
    return new Asserter(values.map(function(v) return Pulse(v)).concat([End]), done, debug).listener;

  var expectations : Array<StreamValue<T>>;
  var done : Void -> Void;
  var debug : Bool;
  public function new(expectations : Array<StreamValue<T>>, done : Void -> Void, debug = false) {
    this.expectations = expectations;
    this.done = done;
    this.debug = debug;
  }
  public function listener(test : StreamValue<T>) {
    if(debug)
      trace(test);
    if(expectations.length == 0)
      Assert.fail('no more expectations but received pulse $test');
    var exp = expectations.shift();
    Assert.same(exp, test);
    switch test {
      case End, Failure(_):
        done();
      case _:
    }
  }
}