package thx.stream;

class TestStream extends Test {
  public function testBasics() {
    var stream = new Stream(assertExpectations([1,2]));
    stream.pulse(1);
    stream.pulse(2);
    stream.end();
  }

  public function testExtraPulse() {
    var stream = new Stream(assertExpectations([1]));
    stream.pulse(1);
    stream.end();
    stream.pulse(2);
  }

  public function testExtraEnd() {
    var stream = new Stream(assertExpectations([]));
    stream.end();
    stream.end();
  }
}