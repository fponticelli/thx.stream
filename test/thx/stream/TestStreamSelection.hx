package thx.stream;

import utest.Assert;
using thx.stream.TestStream;
using thx.stream.StreamExtensions;

class TestStreamSelection {
  public function new() {}

  public function testFilter() {
    Stream.ofValues([1,2,3,4])
      .filter(function(v) return v % 2 == 0)
      .assertValues([2,4]);
  }

  public function testSkip() {
    Stream.ofValues([1,2,3,4])
      .skip(2)
      .assertValues([3,4]);
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

  public function testDistinct() {
    Stream.ofValues([1,1,1,1,2,3,3,3,4,4,1,1,1])
      .distinct()
      .assertValues([1,2,3,4,1]);
  }

  public function testUnique() {
    Stream.ofValues([1,1,2,1,1,2,3,3,3,4,4,1,1,1])
      .unique(Set.createInt())
      .assertValues([1,2,3,4]);
  }

  public function testMin() {
    Stream.ofValues([5,7,3,4,1])
      .min()
      .assertValues([5,3,1]);
  }

  public function testMax() {
    Stream.ofValues([5,7,3,4,1])
      .max()
      .assertValues([5,7]);
  }
}
