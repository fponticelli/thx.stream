package thx.stream;

enum StreamValue<T> {
  Pulse(value : T);
  End(cancel : Bool);
}