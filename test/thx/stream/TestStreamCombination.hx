package thx.stream;

import utest.Assert;
using thx.stream.TestStream;

class TestStreamCombination {
  public function new() {}

  public function testConcat() {
    Stream.ofValue(1)
      .concat(Stream.ofValue(2))
      .concat(Stream.ofValue(3))
      .assertValues([1,2,3]);
  }

  public function testAppendTo() {
    Stream.ofValue(1)
      .appendTo(Stream.ofValue(2))
      .appendTo(Stream.ofValue(3))
      .assertValues([3,2,1]);
  }
}
