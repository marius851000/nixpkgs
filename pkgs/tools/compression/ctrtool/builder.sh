source $stdenv/setup

mkdir ctrtool
cp -r $src/ctrtool/* ctrtool

cd ctrtool
chmod +rwx *

make -j3


mkdir -p $out/bin
cp ctrtool $out/bin
ls
