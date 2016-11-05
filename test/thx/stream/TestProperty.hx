package thx.stream;

import utest.Assert;
import thx.stream.Property;
using thx.stream.TestStream;

class TestProperty {
  public function new() {}

  public function testProperty() {
    var collect = [];
    var prop = new Property(1);
    trace(prop.value);
    Assert.equals(1, prop.value);
    prop.stream()
      .log('value')
      .first()
      .assertValues([1]);
  }
}
