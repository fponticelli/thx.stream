package thx.stream;

import utest.Assert;
import thx.stream.StreamValue;
import thx.stream.Emitter;

class TestStream {
  public function new() {}

  public var emitter: StreamEmitter<Int>;
  public var collect: Array<Int>;
  public function setup() {
    collect = [];
    emitter = Emitter.create();
  }

  public function testOnValue() {
    var st = emitter.stream,
        gotValue = false;
    st.onValue(function(v) {
        Assert.equals(1, v);
        gotValue = true;
      })
      .onError(function(_) Assert.fail('should not fail'))
      .onTerminated(function() Assert.fail('should not terminate'));
    emitter.next(1);
    Assert.isTrue(gotValue);
  }

  public function testOnError() {
    var st = emitter.stream,
        gotValue = false;
    st.onError(function(v) {
        Assert.is(v, thx.Error);
        gotValue = true;
      })
      .onValue(function(_) Assert.fail('should not get value'))
      .onTerminated(function() Assert.fail('should not terminate'));
    emitter.error(new thx.Error('error'));
    Assert.isTrue(gotValue);
  }

  public function testOnTerminated() {
    var st = emitter.stream,
        gotValue = false;
    st.onTerminated(function() {
        gotValue = true;
      })
      .onValue(function(_) Assert.fail('should not get value'))
      .onError(function(_) Assert.fail('should not error'));
    emitter.complete();
    Assert.isTrue(gotValue);
  }

  public function testFlatMap() {
    var s = emitter.stream;
    s.flatMap(function(v) {
        return Stream.lazy(function(e) {
          for(i in 0...v)
            e.next(i);
        });
      })
      .onValue(collect.push.bind(_));
    emitter.next(1);
    emitter.next(2);
    emitter.next(3);
    Assert.same([0,0,1,0,1,2], collect);
  }

  public function testMap() {
    Stream
      .ofValues([1,2,3])
      .onValue(function(v) trace("1", v))
      .map(function(v) return v * 2)
      .onValue(function(v) trace("2", v))
      .collectAll()
      .onValue(function(v) trace("3", v))
      .on(function(v) {
        trace("4", v);
      })
      .onValue(function(v) trace(v))
      .onValue(function(values) {
        Assert.same([2,4,6], values);
      })
      .on(function(v) {
        trace("5", v);
      });
  }

  public function testOfValues() {
    var collect = [];
    Stream.ofValues([1,2,3])
      .onValue(function(v) collect.push(v));
    Assert.same([1,2,3], collect);
  }

  public function testLazy() {
    var inited = 0;
    Stream.lazy(function(e) {
        inited++;
        for(i in 1...4)
          e.next(i);
        e.complete();
      })
      .onValue(function(v) collect.push(v))
      .onValue(function(v) collect.push(v));
    Assert.equals(1, inited);
    Assert.same([1,2,3,1,2,3], collect);
  }
}
