package thx.stream;

import utest.Assert;
using thx.stream.TestStream;
using thx.stream.Observer;

class TestStreamControlFlow {
  public function new() {}

  public function testCaptureProcessExceptions() {
    var canceled = false;
    var done = Assert.createAsync();
    var err = new Error("meh");
    Stream.values([1,2,3])
      .next(function(value) {
        throw err;
      })
      .failure(function(e) {
        Assert.equals(err, e);
        done();
      })
      .run();
  }

  public function testCancelAfterDone() {
    var canceled = false;
    Stream.cancellable(function(o, addCancel) {
      addCancel(function() canceled = true);
      o.done();
    }).assertValues([]);
    Assert.isTrue(canceled);
  }

  public function testNoFlowAfterDone() {
    Stream.create(function(o) {
      o.next(1);
      o.done();
      o.next(2); o.error(new Error("meh")); o.done();
    }).assertSame([Next(1), Done]);
  }

  public function testNoFlowAfterError() {
    var err = new Error("meh");
    Stream.create(function(o) {
      o.next(1);
      o.error(err);
      o.next(2); o.error(new Error("meh")); o.done();
    })
    .assertSame([Next(1), Error(err)]);
  }

  public function testCaptureObserverExceptions() {
    var canceled = false;
    var err = new Error("meh");
    Stream.cancellable(function(o, addCancel) {
        addCancel(function() canceled = true);
        throw err;
      })
      .assertSame([Error(err)]);
  }

  public function testCancelAfterError() {
    var err = new Error("meh");
    var canceled = false;
    Stream.cancellable(function(o, addCancel) {
      addCancel(function() canceled = true);
      o.error(err);
    }).assertSame([Error(err)]);
    Assert.isTrue(canceled);
  }
}
