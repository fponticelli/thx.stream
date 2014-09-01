package thx.stream;

import thx.core.Error;
import thx.promise.Promise;

class Producer<T> {
  var handler : Signer<T> -> (Void -> Void);
  public function new(handler : Signer<T> -> (Void -> Void)) {
    this.handler = handler;
  }
  public function sign(signer : Signer<T>) : Void -> Void {
    var _cancel = handler(signer),
        cancel  = function() {
          _cancel();
          signer(End);
        };
    return function() {
      var c = cancel;
      cancel = function() {};
      c();
    }
  }

  public function subscribe(?pulse : T -> Void, ?failure : Error -> Void, ?end : Void -> Void) : Void -> Void
    return sign({
      pulse   = null == pulse   ? function(_) {} : pulse;
      failure = null == failure ? function(_) {} : failure;
      end     = null == end     ? function( ) {} : end;
      function(r) switch r {
        case Pulse(v):   pulse(v);
        case Failure(e): failure(e);
        case End:        end();
      };
    });

  public function take(number : Int) {
    if(number <= 0) throw '"take" argument should be a positive non zero value';
    return new Producer(function(handler) {
      var counter  = 0,
          cancel   = function() {},
          counterf = function(v) {
            handler(v);
            if(++counter == number)
              cancel();
          };
      return cancel = sign(counterf);
    });
  }

  public function mapValue<TOut>(transform : T -> TOut)
    return new Producer(function(handler)
      return sign(function(r) switch r {
        case Pulse(v): handler(Pulse(transform(v)));
        case Failure(e): handler(Failure(e));
        case End: handler(End);
      })
    );
  public function map<TOut>(transform : T -> Promise<TOut>)
    return new Producer(function(handler)
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
        case End: handler(End);
      })
    );

  public function toPromise() : Promise<Array<T>>
    return Promise.create(function(resolve, reject) {
      var values = [];
      return new Producer(function(handler)
        return sign(function(r)
          switch r {
            case Pulse(v):
              values.push(v);
            case Failure(e):
              reject(e);
            case End:
              resolve(values);
          })
      );
    });

  public function filterValue(filter : T -> Bool)
    return new Producer(function(handler : StreamValue<T> -> Void) {
      return passOn(
        function(value : T) if(filter(value)) handler(Pulse(value)),
        handler
      );
    });
  public function filter(filter : T -> Promise<Bool>)
    return new Producer(function(handler : StreamValue<T> -> Void) {
      return passOn(
        function(value : T) {
          filter(value).then(function(r) {
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

  function passOn(?pulse : T -> Void, ?failure : Error -> Void, ?end : Void -> Void, handler : StreamValue<T> -> Void)
    return subscribe(
        null != pulse   ? pulse   : function(v : T) handler(Pulse(v)),
        null != failure ? failure : function(e : Error) handler(Failure(e)),
        null != end     ? end     : function()  handler(End)
      );

// merge
// sync
// zip
}