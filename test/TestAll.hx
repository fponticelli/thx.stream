import utest.Runner;
import utest.ui.Report;
import utest.Assert;

import thx.stream.*;

class TestAll {
  public static function main() {
    var runner = new Runner();
    runner.addCase(new TestAll());
    runner.addCase(new TestStream());
    runner.addCase(new TestValue());
    Report.create(runner);
    runner.run();
  }

  public function new() {}
}