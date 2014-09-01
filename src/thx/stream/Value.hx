package thx.stream;

import thx.stream.Signer;

class Value<T> extends Producer<T> {
  var value : T;
  var handlers : Array<Signer<T>>;
  var cancels : Array<Void -> Void>;
  public function new(value : T) {
    this.value    = value;
    this.handlers = [];
    this.cancels  = [];
    super(function(handler : Signer<T>) {
      handlers.push(handler);
      handler(Pulse(this.value));
      return function() handlers.remove(handler);
    });
  }

  override function sign(signer : Signer<T>) : Void -> Void {
    var cancel = super.sign(signer);
    cancels.push(cancel);
    return cancel;
  }

  public function get() return value;
  public function set(value : T) {
    if(this.value == value)
      return;
    this.value = value;
    update();
  }

  public function cancel() {
    while(cancels.length > 0) {
      cancels.shift()();
    }
  }

  function update() {
    for(handler in handlers)
      handler(Pulse(value));
  }
}