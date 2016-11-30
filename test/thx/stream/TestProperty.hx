package thx.stream;

import utest.Assert;
import thx.stream.Property;
using thx.stream.TestStream;

class TestProperty {
  public function new() {}

  public function testProperty() {
    var collect = [];
    var prop = new Property(1);
    Assert.equals(1, prop.get());
    prop.stream()
      .first()
      .assertValues([1]);
  }
}
