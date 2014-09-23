package thx.stream;

import thx.promise.Promise;
import thx.core.Tuple;
using thx.stream.Emitter;

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

  public function testPair() {
    Timer.ofArray([1,2,3], 3)
      .pair(Timer.ofArray([5,7], 4))
      .sign(assertExpectations([
        new Tuple2(1,5),
        new Tuple2(2,5),
        new Tuple2(2,7),
        new Tuple2(3,7)
      ]));
  }

  public function testZip() {
    Timer.ofArray([1,2,3], 3)
      .zip(Timer.ofArray([5,7], 4))
      .sign(assertExpectations([
        new Tuple2(1,5),
        new Tuple2(2,7)
      ]));
  }

  public function testSampleBy() {
    Timer.ofArray([1,2,3,4], 3)
      .sampleBy(Timer.ofArray([5,7], 4))
      .sign(assertExpectations([
        new Tuple2(1,5),
        new Tuple2(2,7)
      ]));
  }

  public function testWindow() {
    Timer.ofArray([1,2,3,4,5], 3)
      .window(3)
      .sign(assertExpectations([
        [1,2,3],
        [2,3,4],
        [3,4,5]
      ]));
  }

  public function testWindowWithEarlyEmit() {
    Timer.ofArray([1,2,3,4,5], 3)
      .window(3, true)
      .sign(assertExpectations([
        [1],
        [1,2],
        [1,2,3],
        [2,3,4],
        [3,4,5]
      ]));
  }

  public function testPrevious() {
    Timer.ofArray([1,2,3], 3)
      .previous()
      .sign(assertExpectations([1,2]));
  }

  public function testMapAndWindow() {
    Timer.ofArray([1,2,3], 3)
      .mapValue(function(v) return "" + (v-1))
      .window(2, true)
      .sign(assertExpectations([
        ["0"],
        ["0", "1"],
        ["1", "2"]
      ]));
  }

  public function testMapFieldValue() {
    Timer.ofArray([{ a : 1}, {a : 2}, {a : 3}], 3)
      .mapField(a)
      .sign(assertExpectations([1,2,3]));
  }

  public function testMapFieldMethod() {
    Timer.ofArray([{ a : function(x) return x * 1}, {a : function(x) return x * 2}, {a : function(x) return x * 3}], 3)
      .mapField(a(2))
      .sign(assertExpectations([2,4,6]));
  }

  public function testFloatsSum() {
    Timer.ofArray([1.0,2.0,3.0], 3)
      .sum()
      .sign(assertExpectations([1.0,3.0,6.0]));
  }

  public function testIntsSum() {
    Timer.ofArray([1,2,3], 3)
      .sum()
      .sign(assertExpectations([1,3,6]));
  }

  public function testIntsAverage() {
    Timer.ofArray([1,2,3], 3)
      .average()
      .sign(assertExpectations([1.0,1.5,2.0]));
  }

  public function testIntsMin() {
    Timer.ofArray([3,1,2,3,0], 3)
      .min()
      .sign(assertExpectations([3,1,0]));
  }

  public function testIntsMax() {
    Timer.ofArray([1,3,2,0,3,4], 3)
      .max()
      .sign(assertExpectations([1,3,4]));
  }

  public function testFloatsAverage() {
    Timer.ofArray([1.2,2.0,3.1], 3)
      .average()
      .sign(assertExpectations([1.2,1.6,2.1]));
  }

  public function testFloatsMin() {
    Timer.ofArray([3.3,1.1,2.2,3.3,0], 3)
      .min()
      .sign(assertExpectations([3.3,1.1,0]));
  }

  public function testFloatsMax() {
    Timer.ofArray([1.1,3.3,2.2,0,3.3,4.4], 3)
      .max()
      .sign(assertExpectations([1.1,3.3,4.4]));
  }

  public function testFirst() {
    Timer.ofArray([1,2,3], 3)
      .first()
      .sign(assertExpectations([1]));
  }

  public function testLast() {
    Timer.ofArray([1,2,3], 3)
      .last()
      .sign(assertExpectations([3]));
  }

  public function testTakeLast() {
    Timer.ofArray([1,2,3,4,5,6], 3)
      .takeLast(3)
      .sign(assertExpectations([4,5,6]));
  }

  public function testTakeAt() {
    Timer.ofArray([1,2,3,4,5,6], 3)
      .takeAt(3)
      .sign(assertExpectations([4]));
  }

  public function testSkipUntil() {
    Timer.ofArray([1,2,3,4,5,6,5,4,3,2,1], 3)
      .skipUntil(function(v) return v < 5)
      .sign(assertExpectations([5,6,5,4,3,2,1]));
  }

  public function testSkip() {
    Timer.ofArray([1,2,3,4,5,6,5,4,3,2,1], 3)
      .skip(5)
      .sign(assertExpectations([6,5,4,3,2,1]));
  }

  public function testSplit() {
    var t = Streams.ofArray([for(i in 0...10) Math.random()])
      .split();
    t._0.zip(t._1)
      .mapValue(function(t) return t._0 / t._1)
      .sign(assertExpectations([1.0,1,1,1,1,1,1,1,1,1]));
  }

  public function testDiffWithSeed() {
    Streams.ofArray([1,2,3,6])
      .diff(0, function(prev, next) return next * prev)
      .sign(assertExpectations([0,2,6,18]));
  }

  public function testDiffWithoutSeed() {
    Streams.ofArray([1,2,3,6])
      .diff(function(prev, next) return next / prev)
      .sign(assertExpectations([2.0,1.5,2]));
  }
}