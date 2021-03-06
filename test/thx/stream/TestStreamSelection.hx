package thx.stream;

import utest.Assert;
using thx.stream.TestStream;
using thx.stream.StreamExtensions;

class TestStreamSelection {
  public function new() {}

  public function testFilter() {
    Stream.values([1,2,3,4])
      .filter(function(v) return v % 2 == 0)
      .assertValues([2,4]);
  }

  public function testSkip() {
    Stream.values([1,2,3,4])
      .skip(2)
      .assertValues([3,4]);
  }

  public function testSkipFromEnd() {
    Stream.values([1,2,3,4])
      .skipFromEnd(2)
      .assertValues([1,2]);
  }

  public function testFirst() {
    Stream.values([1,2,3,4])
      .first()
      .assertValues([1]);
  }

  public function testLast() {
    Stream.values([1,2,3,4])
      .last()
      .assertValues([4]);
  }

  public function testDistinct() {
    Stream.values([1,1,1,1,2,3,3,3,4,4,1,1,1])
      .distinct()
      .assertValues([1,2,3,4,1]);
  }

  public function testUnique() {
    Stream.values([1,1,2,1,1,2,3,3,3,4,4,1,1,1])
      .unique(Set.createInt())
      .assertValues([1,2,3,4]);
  }

  public function testMin() {
    Stream.values([5,7,3,4,1])
      .min()
      .assertValues([5,3,1]);
  }

  public function testMax() {
    Stream.values([5,7,3,4,1])
      .max()
      .assertValues([5,7]);
  }

  public function testSampleBy() {
    Stream.values([1,2])
      .sampledBy(Stream.values(["a"]))
      .assertValues([Tuple.of(2, "a")]);
  }

  public function testTakeAt() {
    Stream.values([1,2,3,4,5])
      .takeAt(2)
      .assertValues([3]);
  }

  public function testTake0() {
    Stream.values([1,2,3,4,5])
      .take(0)
      .assertValues([]);
  }

  public function testTake1() {
    Stream.values([1,2,3,4,5])
      .take(1)
      .assertValues([1]);
  }

  public function testTake2() {
    Stream.values([1,2,3,4,5])
      .take(2)
      .assertValues([1,2]);
  }

  public function testWindow() {
    Stream.values([1,2,3,4,5,6,7])
      .window(2)
      .assertValues([[1,2],[3,4],[5,6]]);
  }

  public function testSlidingWindow() {
    Stream.values([1,2,3,4,5])
      .slidingWindow(2,3)
      .assertValues([[1,2],[1,2,3],[2,3,4],[3,4,5]]);
  }
}
