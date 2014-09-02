package thx.stream;

import utest.Assert;
import thx.core.Nil;
import thx.stream.Producer;
import thx.stream.Timer;
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

  public function testConcat() {
    var done = Assert.createAsync(1000);
    Timer.ofArray([1,2,3], 10)
      .concat(Timer.ofArray([4,5,6], 10))
      .sign(Asserter.create([1,2,3,4,5,6], done));
  }

  public function testCancelConcat() {
    var done   = Assert.createAsync(1000),
        cancel = Timer.ofArray([1,2,3], 10)
          .concat(Timer.ofArray([4,5,6], 10))
          .sign(Asserter.create([], done));
    cancel();
  }
}