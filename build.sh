#!/usr/bin/env bash

set -ev
rm -rf dist/
elm make --optimize src/Main.elm
mkdir dist
cp -pir Media assets index.html dist
