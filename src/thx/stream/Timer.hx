package thx.stream;

import thx.core.Nil;

class Timer {
  public static function repeat(repetitions : Int, delay : Int)
    return beacon(delay).take(repetitions);

  public static function beacon(delay : Int) {
    return new Producer(function(signer : Signer<Nil>) {
      var id = thx.core.Timer.repeat(signer.bind(Pulses.nil), delay);
      return function() thx.core.Timer.clear(id);
    });
  }

  public static function sequenceNil<T>(repetitions : Int, delay : Int, build : Nil -> T)
    return repeat(repetitions, delay).mapValue(build);

  public static function sequence<T>(repetitions : Int, delay : Int, build : Void -> T)
    return sequenceNil(repetitions, delay, function(_) return build());

  public static function sequencei<T>(repetitions : Int, delay : Int, build : Int -> T)
    return sequence(repetitions, delay, {
      var i = 0;
      function() return build(i++);
    });

  public static function ofArray<T>(arr : Array<T>, delay : Int)
    return sequencei(arr.length, delay, function(i) return arr[i]);
}