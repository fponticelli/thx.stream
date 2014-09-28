import utest.Runner;
import utest.ui.Report;
import utest.Assert;

import thx.stream.*;

class TestAll {
  public static function main() {
    var runner = new Runner();
    runner.addCase(new TestBus());
    runner.addCase(new TestEmitter());
    runner.addCase(new TestStream());
#if (js || swf)
    runner.addCase(new TestTimer());
#end
    runner.addCase(new TestValue());
    Report.create(runner);
    runner.run();
  }
}