source $stdenv/setup

mkdir makerom
cp -r $src/makerom/* makerom

cd makerom
chmod +rwx *

make -j3


mkdir -p $out/bin
cp makerom $out/bin
