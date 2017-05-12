version     = "0.0.0"
author      = "Xiao-Yong Jin"
description = "Sitmo parallel random number generator in Nim"
license     = "MIT"
srcDir      = "src"

task test, "Runs the test suite":
  withDir "test":
    exec "nim c -r -d:release t"

task docgen, "Regenerate the documentation":
  withDir "doc":
    exec "nim doc2 ../src/sitmo.nim"
