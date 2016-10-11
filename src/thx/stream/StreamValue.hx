package thx.stream;

import thx.Error;

enum StreamValue<T> {
  Value(value : T);
  Error(err: Error);
  Done(canceled : Bool);
}
