import utest.Runner;
import utest.ui.Report;
import utest.Assert;

import thx.stream.*;

class TestAll {
  public static function main() {
    var runner = new Runner();
    runner.addCase(new TestStream());
    runner.addCase(new TestStreamControlFlow());
    // runner.addCase(new TestProperty());
#if (js || swf || java)
    // runner.addCase(new TestTimer());
#end
    Report.create(runner);
    runner.run();
  }
}
