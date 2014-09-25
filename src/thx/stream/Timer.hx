package thx.stream;

import thx.core.Nil;
import thx.core.Timer in T;

class Timer {
  public static function arrayToSequence<T>(arr : Array<T>, delay : Int)
    return sequencei(arr.length, delay, function(i) return arr[i]);

  public static function beacon(delay : Int)
    return new Emitter(function(stream : Stream<Nil>) {
      var cancel = T.repeat(stream.pulse.bind(Nil.nil), delay);
      stream.addCleanUp(cancel);
    });

  public static function repeat(repetitions : Int, delay : Int)
    return beacon(delay).take(repetitions);

  public static function sequence<T>(repetitions : Int, delay : Int, build : Void -> T)
    return repeat(repetitions, delay).map(function(_) return build());

  public static function sequencei<T>(repetitions : Int, delay : Int, build : Int -> T)
    return sequence(repetitions, delay, {
      var i = 0;
      function() return build(i++);
    });

  public static function sequenceNil<T>(repetitions : Int, delay : Int, build : Nil -> T)
    return repeat(repetitions, delay).map(build);
}