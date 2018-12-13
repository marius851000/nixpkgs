{stdenv, fetchurl, x11, gnumake, libXaw, libXpm, Xaw3d}:

stdenv.mkDerivation rec {
  name = "3Dchess-${version}";
  version = "0.8.1";

  src = fetchurl {
    url = "http://www.ibiblio.org/pub/Linux/games/strategy/3Dc-${version}.tar.gz";
    sha256 = "03y7g3200vj65j0ms53i4i3gq04gxq8qqwin1dwafjrh3qs85s3a";
  };

  buildInputs = [ gnumake x11 libXaw libXpm Xaw3d];

  buildPhase = ''
    cd src
    mkdir -p $out/bin
    make BINDIR="$out/bin" install
    '';

  meta = {
    description = "3D chess is kind of a chess game on 3 boards. The pieces are mostly from chess. There are 26 directions to move. 3D chess comes with a computer opponent. ";
    license = stdenv.lib.licenses.gpl2;
  };
}
