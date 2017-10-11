#!/bin/bash
## regression test for a single directory
set -e

cd $(dirname "$0")
source misc.sh
cd ..

case $(uname -a) in
  Linux* ) TIMECMD="/usr/bin/time -o timing.log -f '%U %M'";;
esac

echo

#save the current state
if [ ! -d $1 ]
then
  echo "Ignoring non-existent directory $1"
  exit 0
fi
pushd $1 > /dev/null 2>&1
/bin/rm -f timing.log 2> /dev/null
Holmake cleanAll &&
if eval $TIMECMD Holmake > regression.log 2>&1
then
  echo -n "OK: $1"
  if [ -f timing.log ]
  then
    printf '%0.*s' $((36 - ${#1})) "$pad"
    eval displayline $(cat timing.log)
  else
      echo
  fi
  if [ -x selftest.exe ]
  then
    if ./selftest.exe >> regression.log 2>&1
    then
      echo "OK: $1 (selftest)"
    else
      echo "FAILED: $1 (selftest)"
      cat "$1/regression.log" 1>&1
      exit 1
    fi
  fi
else
  echo "FAILED: $1"
  exit 1
fi
popd > /dev/null 2>&1
