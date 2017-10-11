#!/bin/bash
## A script for downloading cached state for Travis. This file is
## probably obsolete, since Travis is no longer supported.

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
