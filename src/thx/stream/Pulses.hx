package thx.stream;

import thx.core.Nil;

class Pulses {
  public static var nil(default, null) : StreamValue<Nil> = Pulse(Nil.nil);
}