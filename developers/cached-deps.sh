#!/bin/bash
## A script for downloading cached state for Travis. This file is
## probably obsolete, since Travis is no longer supported.

set -e

pushd $HOME
git clone https://github.com/HOL-Theorem-Prover/HOL.git

popd
