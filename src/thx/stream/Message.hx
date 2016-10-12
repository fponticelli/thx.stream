package thx.stream;

import thx.Error;

enum Message<T> {
  Next(value: T);
  Error(err: Error);
  Done;
}
