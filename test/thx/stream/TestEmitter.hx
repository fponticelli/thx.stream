package thx.stream;

import thx.promise.Promise;

class TestEmitter extends Test {
  public function testFromArray() {
    Streams
      .ofArray([1,2,3])
      .sign(assertExpectations([1,2,3]));
  }

  public function testCancelFromArray() {
    var stream = null;
    stream = Streams
      .ofArray([1,2,3])
      .delay(0)
      .sign(assertExpectations([1,2],
        function(v) if(v == 2) stream.cancel(), true));
  }

  public function testMap() {
    Streams
      .ofArray([97,98,99])
      .map(function(v) {
        return Promise.value(String.fromCharCode(v));
      })
      .sign(assertExpectations(['a','b','c']));
  }

  public function testTakeUntil() {
    Streams
      .ofArray([1,2,3,4,5])
      .takeUntil(function(v) return Promise.value(v < 4))
      .sign(assertExpectations([1,2,3]));
  }

  public function testTake() {
    Streams
      .ofArray([1,2,3,4,5])
      .take(3)
      .sign(assertExpectations([1,2,3]));
  }

  public function testTakeZero() {
    Streams
      .ofArray([1,2,3,4,5])
      .take(0)
      .sign(assertExpectations([]));
  }
}