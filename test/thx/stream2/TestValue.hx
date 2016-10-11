package thx.stream;

import utest.Assert;
import thx.Nil;
import thx.stream.Value;
import thx.promise.Promise;
using thx.stream.Streams;

class TestValue extends Test {
  public function testBasic() {
    var value = new Value(10);
    value.sign(assertExpectations([10]));
    value.clearStreams();
  }

  public function testAfter() {
    var value = new Value(10);
    value.sign(assertExpectations([10, 5]));
    value.set(5);
    value.clearStreams();
  }

  public function testBefore() {
    var value = new Value(10);
    value.set(5);
    value.sign(assertExpectations([5]));
    value.clearStreams();
  }

  public function testFeed() {
    var value = new Value(10);
    value.sign(assertExpectations([10,1,2,3]));
    [1,2,3].toStream().feed(value);
    value.clear(); // required because feeding termination doesn't propagate to down streams
  }
}
