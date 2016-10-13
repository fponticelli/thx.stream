package thx.stream;

import utest.Assert;
using thx.stream.TestStream;

class TestStreamSelection {
  public function new() {}

  public function testFilter() {
    Stream.ofValues([1,2,3,4])
      .filter(function(v) return v % 2 == 0)
      .assertValues([2,4]);
  }

  public function testFirst() {
    Stream.ofValues([1,2,3,4])
      .first()
      .assertValues([1]);
  }

  public function testLast() {
    Stream.ofValues([1,2,3,4])
      .last()
      .assertValues([4]);
  }
}
