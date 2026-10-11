#!/usr/bin/env bash

escapedPath="$(echo `pwd` | sed 's/\//\\\//g')"

if grep flutter pubspec.yaml > /dev/null; then
  if [ -d "coverage" ]; then
    # combine line coverage info from package tests to a common file
    if [ ! -d "$MELOS_ROOT_PATH/report" ]; then
      mkdir "$MELOS_ROOT_PATH/report"
    fi
    sed "s/^SF:lib/SF:$escapedPath\/lib/g" coverage/lcov.info >> "$MELOS_ROOT_PATH/report/lcov.info"
    rm -rf "coverage"
  fi

  if [ -f "test.json" ]; then
    # combine test.json from package tests to a common file
    if [ ! -d "$MELOS_ROOT_PATH/report" ]; then
      mkdir "$MELOS_ROOT_PATH/report"
    fi
    sed "s/^SF:lib/SF:$escapedPath\/lib/g" test.json >> "$MELOS_ROOT_PATH/report/test.json"
    rm -rf "test.json"
  fi
fi