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

  public function testFilterValue() {
    Timer.sequencei(6, 10, function(i) return i+1)
      .filterValue(function(v) return v % 2 == 0)
      .sign(assertExpectations([2,4,6]));
  }

  public function testFilter() {
    Timer.sequencei(6, 10, function(i) return i+1)
      .filter(function(v) return Promise.value(v % 2 == 0))
      .sign(assertExpectations([2,4,6]));
  }
  public function testConcat() {
    Timer.ofArray([1,2,3], 10)
      .concat(Timer.ofArray([4,5,6], 10))
      .sign(assertExpectations([1,2,3,4,5,6]));
  }

  public function testCancelConcat() {
    var stream = Timer.ofArray([1,2,3], 10)
          .concat(Timer.ofArray([4,5,6], 10))
          .sign(assertExpectations([], true));
    stream.cancel();
  }

  public function testCancelConcatOnFirstSegment() {
    var stream = null;
    stream = Timer.ofArray([1,2,3], 10)
      .concat(Timer.ofArray([4,5,6], 10))
      .audit(function(v) {
        if(v == 2)
          stream.cancel();
      })
      .sign(assertExpectations([1], true));
  }

  public function testCancelConcatOnSecondSegment() {
    var stream = null;
    stream = Timer.ofArray([1,2,3], 10)
      .concat(Timer.ofArray([4,5,6], 10))
      .audit(function(v) {
        if(v == 5)
          stream.cancel();
      })
      .sign(assertExpectations([1,2,3,4], true));
  }

  public function testCancelMerge() {
    var stream = Timer.ofArray([1,2,3], 10)
          .merge(Timer.ofArray([4,5,6], 10))
          .sign(assertExpectations([], true));
    stream.cancel();
  }

  public function testCancelMergeOnFirst() {
    var stream = null;
    stream = Timer.ofArray([1,2,3], 10)
      .merge(Timer.ofArray([4,5,6], 10))
      .audit(function(v) {
        if(v == 5)
          stream.cancel();
      })
      .sign(assertExpectations([1,4,2], true));
  }

  public function testCancelMergeOnSecond() {
    var stream = null;
    stream = Timer.ofArray([1,2,3], 10)
      .merge(Timer.ofArray([4,5,6], 10))
      .audit(function(v) {
        if(v == 2)
          stream.cancel();
      })
      .sign(assertExpectations([1,4], true));
  }

  public function testReduce() {
    Timer.ofArray([1,2,3,4], 10)
      .reduce(0, function(acc, value) return acc + value)
      .sign(assertExpectations([1,3,6,10]));
  }

  public function testDebounce() {
    Timer.ofArray([1,2,3,4], 2)
      .debounce(25)
      .sign(assertExpectations([4]));
  }

  public function testDistinct() {
    Timer.ofArray([1,1,1,1,2,2,2,3,3], 2)
      .distinct()
      .sign(assertExpectations([1,2,3]));
  }
}