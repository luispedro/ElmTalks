#!/usr/bin/env bash

set -ev
if test -d dist/ ; then
    rm -rf dist.backup
    mv dist dist.backup
fi
rm -rf dist/
elm make --optimize src/Main.elm
mkdir dist
cp -pir assets index.html dist
python copy-Media-files.py
