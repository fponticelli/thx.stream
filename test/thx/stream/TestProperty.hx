package thx.stream;

import utest.Assert;
import thx.stream.StreamValue;
import thx.stream.Emitter;

class TestProperty {
  public function new() {}

  public function testProperty() {
    var collect = [];
    var prop = new Property(1);
    Assert.equals(1, prop.value);
    prop.stream.onValue(collect.push);
    Assert.same([1], collect);
  }}
