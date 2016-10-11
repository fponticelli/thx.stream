package thx.stream;

import utest.Assert;
import thx.stream.StreamValue;
import thx.stream.Emitter;

class TestEmitter {
  public function new() {}

  public var emitter: StreamEmitter<Int>;
  public var collect: Array<StreamValue<Int>>;
  public function setup() {
    collect = [];
    emitter = Emitter.create();
    emitter.stream.on(function(v) collect.push(v));
  }

  public function testEmit() {
    emitter.next(1);
    emitter.next(2);
    emitter.next(3);
    emitter.complete();
    Assert.same([
      Value(1),
      Value(2),
      Value(3),
      Done(false)
    ], collect);
  }

  public function testNoEmitsAfterError() {
    var err = new thx.Error("meh");
    emitter.next(1);
    emitter.error(err);
    emitter.next(2);
    Assert.same([
      Value(1),
      Error(err)
    ], collect);
  }

  public function testNoEmitsAfterDone() {
    emitter.next(1);
    emitter.complete();
    emitter.next(2);
    Assert.same([
      Value(1),
      Done(false)
    ], collect);
  }

  public function testNoEmitsAfterCancel() {
    emitter.next(1);
    emitter.cancel();
    emitter.next(2);
    Assert.same([
      Value(1),
      Done(true)
    ], collect);
  }

  public function testInterceptError() {
    var err = new thx.Error("break");
    var emitter = Emitter.create();
    var collect = [];
    emitter.stream.on(function(v) {
      collect.push(v);
    });
    emitter.next(1);
    emitter.error(err);
    emitter.next(2);
    Assert.same([Value(1), Error(err)], collect);
  }

  public function testInterceptException() {
    var err = new thx.Error("break");
    var emitter = Emitter.create();
    var collect = [];
    emitter.stream.on(function(v) {
      switch v {
        case Value(1): collect.push(v);
        case Value(_): throw err;
        case _: collect.push(v);
      };
    });
    emitter.next(1);
    emitter.next(2);
    Assert.same([Value(1), Error(err)], collect);
  }

  public function testVolatile() {
    var emitter = Emitter.volatile();
    var collect = [];
    // events here are not propagated
    emitter.next(1);
    emitter.stream.onValue(collect.push);
    // events will be propagate here once a handler is attached
    Assert.same([], collect);
    emitter.next(2);
    Assert.same([2], collect);
  }
}
