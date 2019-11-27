version     = "0.0.2"
author      = "Xiao-Yong Jin"
description = "Sitmo parallel random number generator in Nim"
license     = "MIT"
srcDir      = "src"

task test, "Runs the test suite":
  --define: release
  --path: "src"
  --run
  setCommand "c", "test/t.nim"

task docgen, "Regenerate the documentation":
  exec "nim doc2 --out:doc/sitmo.html src/sitmo.nim"
