package thx.stream;

import thx.Nil;

class TestTimer extends Test {
  public function testBeacon() {
    var counter = 0,
        stream  = null;
    stream = Timer
      .repeat(10)
      .sign(
        assertExpectations(
          [nil,nil,nil],
          function(_) if(++counter == 3) stream.cancel(),
          true
        )
      );
  }

  public function testSequence() {
    Timer.sequence(3, 10, (function() {
      var i = 0;
      return function () return ++i;
    })()).sign(assertExpectations([1,2,3]));
  }

  public function testSequencei() {
    Timer.sequencei(3, 10, function(i) return i * 2).sign(assertExpectations([0,2,4]));
  }
}