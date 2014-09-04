package thx.stream;

import thx.core.Error;

class Stream<T> implements IStream {

  var subscriber : StreamValue<T> -> Void;
  var cleanUps : Array<Void -> Void>;
  var finalized : Bool;
  public var canceled(default, null) : Bool;
  public function new(subscriber : StreamValue<T> -> Void) {
    this.subscriber = subscriber;
    this.cleanUps   = [];
    this.finalized  = false;
    this.canceled   = false;
  }

  public function addCleanUp(f : Void -> Void) {
    cleanUps.push(f);
  }

  public function pulse(v : T) {
    subscriber(Pulse(v));
  }

  public function end() {
    finalize(End(false));
  }

  public function cancel() {
    canceled = true;
    finalize(End(true));
  }

  public function fail(error : Error) {
    finalize(Failure(error));
  }

  function finalize(signal : StreamValue<T>) {
    if(finalized) return;
    finalized = true;
    while(cleanUps.length > 0)
      cleanUps.shift()();
    subscriber(signal);
    subscriber = function(_) {};
  }
}