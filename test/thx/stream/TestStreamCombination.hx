package thx.stream;

import utest.Assert;
using thx.stream.TestStream;

class TestStreamCombination {
  public function new() {}

  public function testConcat() {
    Stream.value(1)
      .concat(Stream.value(2))
      .concat(Stream.value(3))
      .assertValues([1,2,3]);
  }

  public function testAppendTo() {
    Stream.value(1)
      .appendTo(Stream.value(2))
      .appendTo(Stream.value(3))
      .assertValues([3,2,1]);
  }

  public function testZip() {
    Stream.values([1,2,3])
      .zip(Stream.values(["a", "b", "c", "d"]))
      .assertValues([Tuple.of(1, "a"),Tuple.of(2, "b"),Tuple.of(3, "c")]);

    Stream.values([1,2,3,4])
      .zip(Stream.values(["a", "b"]))
      .assertValues([Tuple.of(1, "a"),Tuple.of(2, "b")]);
  }

  public function testAlternate() {
    Stream.values([1,3,5])
      .alternate(Stream.values([2,4]))
      .assertValues([1,2,3,4,5]);

    Stream.values([1,3,5])
      .alternate(Stream.values([2,4,6]))
      .assertValues([1,2,3,4,5,6]);

    Stream.values([1,3,5])
      .alternate(Stream.values([]))
      .assertValues([1]);

    Stream.values([1,3,5])
      .alternate(Stream.values([2]))
      .assertValues([1,2,3]);

    Stream.values([1])
      .alternate(Stream.values([2]))
      .assertValues([1,2]);

    Stream.values([1])
      .alternate(Stream.values([2,4]))
      .assertValues([1,2]);
  }
}
