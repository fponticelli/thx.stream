package thx.stream;

import utest.Assert;
using thx.stream.TestStream;
using thx.stream.StreamExtensions;

class TestStreamTransform {
  public function new() {}

  public function testMap() {
    Stream.values([0,1,2])
      .map(function(v) return v * 2)
      .assertValues([0,2,4]);
  }

  public function testFlatMap() {
    Stream.values([0,1,2,3])
      .flatMap(function(v) return Stream.iterator(0...v))
      .assertValues([0,0,1,0,1,2]);
  }

  public function testReduce() {
    Stream.iterator(0...4)
      .reduce(function(a, b) return a + b, 0)
      .assertValues([0, 1, 3, 6]);
  }

  public function testFold() {
    Stream.iterator(0...4)
      .fold(function(a, b) return a + b)
      .assertValues([0, 1, 3, 6]);
  }

  public function testCollect() {
    Stream.iterator(0...3)
      .collect()
      .assertValues([[0], [0,1], [0,1,2]]);
  }

  public function testCollectAll() {
    Stream.iterator(0...3)
      .collectAll()
      .assertValues([[0,1,2]]);
  }

  public function testFlatten() {
    Stream.value([1,2,3])
      .flatten()
      .assertValues([1,2,3]);
  }

  public function testSum() {
    Stream.values([1,2,3])
      .sum()
      .assertValues([1,3,6]);
  }

  public function testAverage() {
    Stream.values([1,2,3])
      .average()
      .assertValues([1.0,1.5,2]);
  }
}
