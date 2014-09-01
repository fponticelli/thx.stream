package thx.stream;

import utest.Assert;
import thx.core.Nil;
import thx.stream.Producer;
import thx.stream.Value;
import thx.promise.Promise;

class TestValue {
  public function new() {}

  public function testBasic() {
    var done  = Assert.createAsync(200),
        value = new Value(10);
    value.sign(Asserter.create([10], done));
    value.cancel();
  }

  public function testAfter() {
    var done  = Assert.createAsync(200),
        value = new Value(10);
    value.sign(Asserter.create([10, 5], done));
    value.set(5);
    value.cancel();
  }

  public function testBefore() {
    var done  = Assert.createAsync(200),
        value = new Value(10);
    value.set(5);
    value.sign(Asserter.create([5], done));
    value.cancel();
  }
}