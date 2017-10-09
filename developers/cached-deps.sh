#!/bin/bash
## A script for downloading cached state for Travis. This file is
## probably obsolete, since Travis is no longer supported.

set -e

pushd $HOME
git clone https://github.com/HOL-Theorem-Prover/HOL.git
cd HOL
echo 'val polymllibdir = "/usr/lib/x86_64-linux-gnu/";' > tools-poly/poly-includes.ML 
poly < tools-poly/smart-configure.sml
./bin/build

popd
