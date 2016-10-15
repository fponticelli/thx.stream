package thx.stream;

import utest.Assert;
using thx.Iterators;
using thx.Functions;
using thx.Tuple;
using thx.stream.StreamExtensions;
using thx.stream.TestStream;

class TestStreamAsync {
  public function new() {}

  public function testDelay() {
    var before = true;
    Stream
      .delayValue(5, 1)
      .effect(function(_) Assert.isFalse(before))
      .assertValues([1]);
    before = false;
  }

  public function testDelayed() {
    var before = true;
    Stream
      .ofValue(1)
      .delayed(5)
      .effect(function(_) Assert.isFalse(before))
      .assertValues([1]);
    before = false;
  }

  public function testRepeat() {
    Stream
      .repeat(1)
      .take(5)
      .withIndex()
      .assertValues([0,1,2,3,4]);
  }

  public function testFrame() {
    Stream
      .frame()
      .skip(1) // first frame can happen almost instantaneously
      .take(5)
      .withIndex()
      .assertCheckValues(function(values: Array<Tuple<Int, Float>>) {
        if(values.length == 0) return false;
        for(value in values) if(value._1 <= 0)
          return false;
        return true;
      });
  }

  public function testSpaced() {
    var before = true;
    Stream
      .ofValues([1,2,3,4,5])
      .spaced(10)
      .skipFirst()
      .effect(function(_) Assert.isFalse(before))
      .assertValues([2,3,4,5]);
    before = false;
  }

  public function testDebounce() {
    var before = true;
    Stream
      .ofValues([1,2,3,4,5])
      .debounce(10)
      .effect(function(_) Assert.isFalse(before))
      .assertValues([5]);
    before = false;
  }
}
