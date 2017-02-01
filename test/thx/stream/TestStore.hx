package thx.stream;

import utest.Assert;
import thx.stream.Reducer;
import thx.stream.Store;
using thx.stream.TestStream;
using thx.promise.Promise;

class TestStore {
  public function new() {}

  public function testStore() {
    var store = withReducer(1);
    Assert.equals(1, store.get());
    store.dispatch(Increment);
    Assert.equals(2, store.get());
    store.dispatch(Decrement);
    Assert.equals(1, store.get());
    store.dispatch(SetTo(0));
    Assert.equals(0, store.get());
  }

  public function testStreamInitialValue() {
    var store = withReducer(0);
    store
      .stream()
      .assertFirstValues([0]);
  }

  public function testStream() {
    var store = withReducer(0);
    store
      .stream()
      .assertFirstValues([0,1,3]);
    store
      .dispatch(Increment)
      .dispatch(SetTo(3));
  }

  public function testMiddleware() {
    var store = withMiddleware(0);
    store
      .stream()
      .assertFirstValues([0,1,10]);
    store
      .dispatch(Increment);
  }

  public function reducer(state: Int, message: TestStoreMessage) {
    return switch message {
      case Increment: state + 1;
      case Decrement: state - 1;
      case SetTo(value): value;
    };
  }

  public function middleware(_, message: TestStoreMessage, f): Void {
    switch message {
      case Increment: f(SetTo(10));
      case _:
    };
  }

  public function withReducer(initial) {
    var prop = new Property(initial);
    return new Store(prop, reducer, Middleware.empty());
  }

  public function withMiddleware(initial) {
    var prop = new Property(initial);
    return new Store(prop, reducer, middleware);
  }
}

enum TestStoreMessage {
  Increment;
  Decrement;
  SetTo(value: Int);
}
