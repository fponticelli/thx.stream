package thx.stream;

import utest.Assert;
import thx.core.Nil;
import thx.stream.Value;
import thx.promise.Promise;

class TestBus extends Test {
  public function testBasic() {
    var bus = new Bus();
    bus.sign(assertExpectations([10]));
    bus.pulse(10);
    bus.clearStreams();
  }
}