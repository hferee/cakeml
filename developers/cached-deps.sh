#!/bin/bash
## A script for installing hol for travis

set -e
pushd $HOME

if [ ! -d "HOL" ] ; then
    git clone "https://github.com/HOL-Theorem-Prover/HOL.git" "HOL"
fi
cd HOL
git pull
./bin/build --nograph || (
    echo 'val polymllibdir = "/usr/lib/x86_64-linux-gnu/";' > tools-poly/poly-includes.ML;
    poly < tools-poly/smart-configure.sml;
    ./bin/build --nograph)



popd
