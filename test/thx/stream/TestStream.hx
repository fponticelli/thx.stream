package thx.stream;

import utest.Assert;
using thx.stream.TestStream;

class TestStream {
  public static function assertSame<T>(stream: Stream<T>, expected: Array<Message<T>>, ?pos: haxe.PosInfos) {
    var collect = [];
    stream
      // .logMessage("assert")
      .message(collect.push)
      .always(function() Assert.same(expected, collect, 'expected ${expected} but got ${collect}', pos))
      .always(Assert.createAsync())
      .run();
  }

  public static function assertValues<T>(stream: Stream<T>, expected: Array<T>, ?pos: haxe.PosInfos) {
    assertSame(stream, expected.map(thx.stream.Message.Next).concat([Done]), pos);
  }

  public static function assertCheck<T>(stream: Stream<T>, check: Array<Message<T>> -> Bool, ?pos: haxe.PosInfos) {
    var collect = [];
    stream
      .message(collect.push)
      .always(function() Assert.isTrue(check(collect), 'failed check on ${collect}', pos))
      .always(Assert.createAsync())
      .run();
  }

  public static function assertCheckValues<T>(stream: Stream<T>, check: Array<T> -> Bool, ?pos: haxe.PosInfos) {
    var collect = [];
    stream
      .next(collect.push)
      .always(function() Assert.isTrue(check(collect), 'failed check on ${collect}', pos))
      .always(Assert.createAsync())
      .run();
  }
}
