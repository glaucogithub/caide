#!/bin/bash
set -ev

date

sudo apt update
sudo apt install git g++ cmake cabal-install ghc binutils python2.7 ccache

cmake --version
g++ --version
ghc --version
date

git submodule update --init --recursive
date

cd libcaide
cabal sandbox init
cabal update -v
cabal install --only-dependencies
date

export CXX=`readlink -f $CIRCLE_WORKING_DIRECTORY/.circleci/ccache-g++`
echo $CXX

cabal configure
cabal build --ghc-options="-pgml $CXX"
date

sudo apt install phantomjs mono-mcs wget curl
date

export MONO=mono
export CSC=mcs
export QT_QPA_PLATFORM=offscreen
tests/run-tests.sh
date

