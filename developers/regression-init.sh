#!/bin/bash
## Initialise regression test

set -e

echo "Running regression test on $(git log -1 --oneline --no-color)"
HOLDIR=$(heapname | xargs dirname) || exit $?
echo "HOL revision: $(cd $HOLDIR; git log -1 --oneline --no-color)"
echo "Machine: $(uname -nmo)"

if [ -n "$(git status -z)" ]
then
    echo "WARNING: working directory is dirty!"
fi

