package thx.stream;

import utest.Assert;
import thx.stream.StreamValue;

class Test {
  public function new() {}

  static function expectations<T>(values : Array<T>, isCancel : Bool = false) : Array<StreamValue<T>> {
    return values.map(function(v) return Pulse(v)).concat([End(isCancel)]);
  }

  function assertExpectations<T>(values : Array<T>, ?callback : T -> Void, isCancel : Bool = false, ?done : Void -> Void, ?pos : haxe.PosInfos) : StreamValue<T> -> Void {
    return assertSubscriber(expectations(values, isCancel), callback, done, pos);
  }

  function assertSubscriber<T>(expectations : Array<StreamValue<T>>, ?callback : T -> Void, ?done : Void -> Void, ?pos : haxe.PosInfos) : StreamValue<T> -> Void {
    callback = null == callback ? function(_) {} : callback;
    done = null == done ? Assert.createAsync(2000) : done;
    return function(test : StreamValue<T>) {
      if(expectations.length == 0) {
        Assert.fail('no more expected values but reaceived $test');
        return;
      }
      var expected = expectations.shift();
      Assert.same(expected, test, pos);
      switch test {
        case Pulse(v): callback(v);
        case _:
          if(expectations.length == 0)
             done();
      }
    };
  }
}
