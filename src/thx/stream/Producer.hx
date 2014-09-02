package thx.stream;

import thx.core.Error;
import thx.core.Nil;
import thx.promise.Promise;
import haxe.ds.Option;

class FlowProducer<T> extends Producer<T> {
  override public function sign(signer : Signer<T>) : Void -> Void {
    var cancel = handler(signer);
    return function() {
      var c = cancel;
      cancel = function() {};
      c();
    };
  }
}

class Producer<T> {
  var handler : Signer<T> -> (Void -> Void);
  public function new(handler : Signer<T> -> (Void -> Void)) {
    this.handler = handler;
  }
  public function sign(signer : Signer<T>) : Void -> Void {
    var _cancel = handler(signer),
        cancel  = function() {
          _cancel();
          signer(End(true));
          signer = function(_) {};
        };
    return function() {
      var c = cancel;
      cancel = function() {};
      c();
    };
  }

  public function subscribe(?pulse : T -> Void, ?failure : Error -> Void, ?end : Bool -> Void) : Void -> Void
    return sign({
      pulse   = null == pulse   ? function(_) {} : pulse;
      failure = null == failure ? function(_) {} : failure;
      end     = null == end     ? function(_) {} : end;
      function(r) switch r {
        case Pulse(v):   pulse(v);
        case Failure(e): failure(e);
        case End(c):     end(c);
      };
    });

  public function take(number : Int) {
    if(number <= 0) throw '"take" argument should be a positive non zero value';
    return new FlowProducer(function(handler) {
      var counter  = 0,
          cancel   = function() {};
      return cancel = subscribe(
        function(v) {
          handler(Pulse(v));
          if(++counter == number)
            cancel();
        },
        function(c : Bool) handler(End(counter == number ? false : c)));
    });
  }

  public function mapValue<TOut>(transform : T -> TOut)
    return map(function(t) {
      return Promise.value(transform(t));
    });

  public function map<TOut>(transform : T -> Promise<TOut>)
    return new FlowProducer(function(handler) {
      return sign(function(r) switch r {
        case Pulse(v):
          transform(v).then(function(r) {
            switch r {
              case Success(v):
                handler(Pulse(v));
              case Failure(e):
                handler(Failure(e));
            }
          });
        case Failure(e): handler(Failure(e));
        case End(c):     handler(End(c));
      });
    });

  public function toPromise() : Promise<Array<T>>
    return Promise.create(function(resolve, reject) {
      var values = [];
      return new FlowProducer(function(handler)
        return sign(function(r)
          switch r {
            case Pulse(v):   values.push(v);
            case Failure(e): reject(e);
            case End(_):     resolve(values);
          })
      );
    });

  public function filterValue(filterf : T -> Bool)
    return filter(function(v : T) return Promise.value(filterf(v)));

  public function filter(filterf : T -> Promise<Bool>)
    return new FlowProducer(function(handler : StreamValue<T> -> Void) {
      return passOn(
        function(value : T) {
          filterf(value).then(function(r) {
            switch r {
              case Success(p):
                if(p)
                  handler(Pulse(value));
              case Failure(e):
                handler(Failure(e));
            }
          });
        },
        handler
      );
    });
  public function toOption() : Producer<Option<T>>
    return mapValue(function(v) return null == v ? None : Some(v));
  public function toNil() : Producer<Nil>
    return mapValue(function(_) return nil);
  public function toTrue() : Producer<Bool>
    return mapValue(function(_) return true);
  public function toFalse() : Producer<Bool>
    return mapValue(function(_) return false);
  public function log(?prefix : String, ?posInfo : haxe.PosInfos) {
    prefix = prefix == null ? '': '${prefix}: ';
    return mapValue(function(v) {
      haxe.Log.trace('$prefix$v', posInfo);
      return v;
    });
  }

  public function withValue(?expected : T) : Producer<T>
    if(null == expected)
      return filterValue(function(v : T) return v != null)
    else
      return filterValue(function(v : T) return v == expected);

  public function concat(other : Producer<T>) : Producer<T>
    return new FlowProducer(function(handler) {
      var cancel;
      cancel = passOn(function(c : Bool) {
          if(c)
            return handler(End(c));
          cancel = other.passOn(handler);
        }, handler);
      return function() {
        cancel();
        cancel = function(){ trace("RECANCEL");};
      }
    });
// blend
// keep
// debounce
// sampleBy
// pair
// distinct
// merge
// sync
// zip
// previous
// public function window(length : Int, fillBeforeEmit = false) : Producer<T> // or unique
// public function reduce(acc : TOut, TOut -> T) : Producer<TOut>
// public function debounce(delay : Int) : Producer<T>
// exact pair
// public function zip<TOther>(other : Producer<TOther>) : Producer<Tuple<T, TOther>> // or sync

// mapFilter?

/*
  public static function filterOption<T>(producer : Producer<Option<T>>) : Producer<T>
    return producer
      .filter(function(opt) return switch opt { case Some(_): true; case None: false; })
      .map(function(opt) return switch opt { case Some(v) : v; case None: throw 'filterOption failed'; });

  public static function toValue<T>(producer : Producer<Option<T>>) : Producer<Null<T>>
    return producer
      .map(function(opt) return switch opt { case Some(v) : v; case None: null; });

  public static function toBool<T>(producer : Producer<Option<T>>) : Producer<Bool>
    return producer
      .map(function(opt) return switch opt { case Some(_) : true; case None: false; });

  public static function skipNull<T>(producer : Producer<Null<T>>) : Producer<T>
    return producer
      .filter(function(value) return null != value);

  public static function left<TLeft, TRight>(producer : Producer<Tuple2<TLeft, TRight>>) : Producer<TLeft>
    return producer.map(function(v) return v._0);

  public static function right<TLeft, TRight>(producer : Producer<Tuple2<TLeft, TRight>>) : Producer<TRight>
    return producer.map(function(v) return v._1);

  public static function negate(producer : Producer<Bool>)
    return producer.map(function(v) return !v);

  public static function flatMap<T>(producer : Producer<Array<T>>) : Producer<T> {
    return new FlowProducer(function(forward : Pulse<T> -> Void) {
      producer.feed(Bus.passOn(
        function(arr : Array<T>) arr.map(function(value) forward(Emit(value))),
        forward
      ));
    }, producer.endOnError);
  }

  public static function delayed<T>(producer : Producer<T>, delay : Int) : Producer<T> {
    return new FlowProducer(function(forward) {
      producer.feed(new Bus(
        function(v)
          Timer.setTimeout(function() forward(Emit(v)), delay),
        function()
          Timer.setTimeout(function() forward(End), delay),
        function(error)
          Timer.setTimeout(function() forward(Fail(error)), delay)
      ));
    }, producer.endOnError);
  }

@:access(steamer.Producer)
class ProducerProducer {
  public static function flatMap<T>(producer : Producer<Producer<T>>) : Producer<T> {
    return new FlowProducer(function(forward : Pulse<T> -> Void) {
      producer.feed(Bus.passOn(
        function(prod : Producer<T>) {
          prod.feed(Bus.passOn(
            function(value : T) forward(Emit(value)),
            forward
          ));
        },
        forward
      ));
    }, producer.endOnError);
  }
}

class StringProducer {
  public static function toBool(producer : Producer<String>) : Producer<Bool>
    return producer
      .map(function(s) return s != null && s != "");
}
*/
  public static function ofArray<T>(arr : Array<T>)
    return new FlowProducer(function(handler) {
      arr.map(function(v) handler(Pulse(v)));
      return function(){};
    });

  function passOn(?pulse : T -> Void, ?failure : Error -> Void, ?end : Bool -> Void, handler : StreamValue<T> -> Void)
    return subscribe(
        null != pulse   ? pulse   : function(v : T)     handler(Pulse(v)),
        null != failure ? failure : function(e : Error) handler(Failure(e)),
        null != end     ? end     : function(c : Bool)  handler(End(c))
      );
}