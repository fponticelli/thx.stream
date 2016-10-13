package thx.stream;

import utest.Assert;
using thx.Iterators;
using thx.Functions;
using thx.Tuple;
using thx.stream.StreamExtensions;
using thx.stream.TestStream;

class TestStreamAsync {
  public function new() {}

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
      .take(5)
      .withIndex()
      .assertCheckValues(function(values: Array<Tuple<Int, Float>>) {
        if(values.length == 0) return false;
        for(value in values) if(value._1 <= 0)
          return false;
        return true;
      });
  }
}
