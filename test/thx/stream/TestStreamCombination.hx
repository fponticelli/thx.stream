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

  public function testZip() {
    Stream.ofValues([1,2,3])
      .zip(Stream.ofValues(["a", "b", "c", "d"]))
      .assertValues([Tuple.of(1, "a"),Tuple.of(2, "b"),Tuple.of(3, "c")]);

    Stream.ofValues([1,2,3,4])
      .zip(Stream.ofValues(["a", "b"]))
      .assertValues([Tuple.of(1, "a"),Tuple.of(2, "b")]);
  }

  public function testAlternate() {
    Stream.ofValues([1,3,5])
      .alternate(Stream.ofValues([2,4]))
      .assertValues([1,2,3,4,5]);

    Stream.ofValues([1,3,5])
      .alternate(Stream.ofValues([2,4,6]))
      .assertValues([1,2,3,4,5,6]);

    Stream.ofValues([1,3,5])
      .alternate(Stream.ofValues([]))
      .assertValues([1]);

    Stream.ofValues([1,3,5])
      .alternate(Stream.ofValues([2]))
      .assertValues([1,2,3]);

    Stream.ofValues([1])
      .alternate(Stream.ofValues([2]))
      .assertValues([1,2]);

    Stream.ofValues([1])
      .alternate(Stream.ofValues([2,4]))
      .assertValues([1,2]);
  }
}
