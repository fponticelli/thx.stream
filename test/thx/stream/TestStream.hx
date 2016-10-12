package thx.stream;

import utest.Assert;
using thx.Iterators;
using thx.Functions;
using thx.stream.TestStream;

class TestStream {
  public function new() {}

  public function testNew() {
    var stream = new Stream(function(l) {
      (0...3).forEach.fn(l(Next(_)));
      l(Done);
      return function() {};
    });

    stream.assertValues([0,1,2]);
  }

  public function testCreate() {
    var stream = Stream.create(function(o) {
      (0...3).forEach(o.next);
      o.done();
    });

    stream.assertValues([0,1,2]);
  }

  public function testOfValues() {
    Stream.ofValues([0,1,2]).assertValues([0,1,2]);
    Stream.ofIterator(0...3).assertValues([0,1,2]);
  }

  public function testMap() {
    Stream.ofValues([0,1,2])
      .map(function(v) return v * 2)
      .assertValues([0,2,4]);
  }

  public function testFlatMap() {
    Stream.ofValues([0,1,2,3])
      .flatMap(function(v) return Stream.ofIterator(0...v))
      .assertValues([0,0,1,0,1,2]);
  }

  public function testReduce() {
    Stream.ofIterator(0...4)
      .reduce(function(a, b) return a + b, 0)
      .assertValues([0, 1, 3, 6]);
  }

  public function testFold() {
    Stream.ofIterator(0...4)
      .fold(function(a, b) return a + b)
      .assertValues([1, 3, 6]);
  }

  public static function assertSame<T>(stream: Stream<T>, expected: Array<Message<T>>, ?pos: haxe.PosInfos) {
    var collect = [];
    stream
      .message(collect.push)
      .always(function() Assert.same(expected, collect, 'expected ${expected} but got ${collect}', pos))
      .always(Assert.createAsync())
      .run();
  }

  public static function assertValues<T>(stream: Stream<T>, expected: Array<T>, ?pos: haxe.PosInfos) {
    assertSame(stream, expected.map(thx.stream.Message.Next).concat([Done]), pos);
  }
}
