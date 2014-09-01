package thx.stream;

import utest.Assert;
import thx.stream.Producer;
import thx.stream.Timer;
import thx.stream.StreamValue;
import thx.core.Error;
import thx.core.Nil;
import thx.promise.Promise;

class TestStream {
  public function new() {}

  public function testBasic() {
    var done = Assert.createAsync(1000);
    Timer.repeat(3, 10).sign(Asserter.create([nil, nil, nil], done));
  }

  public function testSequence() {
    var done = Assert.createAsync(1000);
    Timer.sequence(3, 10, (function() {
      var i = 0;
      return function () return ++i;
    })()).sign(Asserter.create([1,2,3], done));
  }

  public function testSequencei() {
    var done = Assert.createAsync(1000);
    Timer.sequencei(3, 10, function(i) return i * 2).sign(Asserter.create([0,2,4], done));
  }

  public function testFilterValue() {
    var done = Assert.createAsync(1000);
    Timer.sequencei(6, 10, function(i) return i+1)
      .filterValue(function(v) return v % 2 == 0)
      .sign(Asserter.create([2,4,6], done));
  }

  public function testFilter() {
    var done = Assert.createAsync(1000);
    Timer.sequencei(6, 10, function(i) return i+1)
      .filter(function(v) return Promise.value(v % 2 == 0))
      .sign(Asserter.create([2,4,6], done));
  }
}

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