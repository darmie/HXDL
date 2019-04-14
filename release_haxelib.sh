#!/bin/sh
rm -f hxdl.zip
zip -r hxdl.zip src *.hxml *.json *.md run.n
haxelib submit hxdl.zip $HAXELIB_PWD --always