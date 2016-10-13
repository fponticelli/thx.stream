import utest.Runner;
import utest.ui.Report;
import utest.Assert;

import thx.stream.*;

class TestAll {
  public static function main() {
    var runner = new Runner();
#if (js || swf)
    runner.addCase(new TestStreamAsync());
#end
    runner.addCase(new TestStreamCombination());
    runner.addCase(new TestStreamControlFlow());
    runner.addCase(new TestStreamCreate());
    runner.addCase(new TestStreamSelection());
    runner.addCase(new TestStreamTransform());
    // runner.addCase(new TestProperty());
    // runner.addCase(new TestTimer());
    Report.create(runner);
    runner.run();
  }
}
