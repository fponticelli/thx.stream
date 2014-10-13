#!/bin/sh
rm thx.stream.zip
zip -r thx.stream.zip hxml src test doc/ImportStream.hx extraParams.hxml haxelib.json LICENSE README.md
haxelib submit thx.stream.zip