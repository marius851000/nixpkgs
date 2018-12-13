{ stdenv, fetchurl, SDL, SDL_mixer }:

stdenv.mkDerivation rec {
  name = "defendguin-${version}";
  version = "0.0.12";

  src = fetchurl {
    url = "ftp://ftp.tuxpaint.org/unix/x/defendguin/src/defendguin-${version}.tar.gz";
    sha256 = "0c3k0533z1xr7y76zza7za6x5ribjpf2b5ahnw0ija8b93nqn91w";
  };

  buildInputs = [ SDL SDL_mixer ];

  buildPhase = ''
    make PREFIX="$out"
  '';

  installPhase = ''
    mkdir -p $out/bin
    make PREFIX="$out" install
  '';

  meta = {
    homepage = http://www.newbreedsoftware.com/defendguin/;
    downloadPage = http://www.newbreedsoftware.com/defendguin/download/;
    description = "A game based on the arcade game \"Defender\".";
    longDescription = "Defendguin is a clone of the arcade game \"Defender,\" but with a Linux theme. Your mission is to defend little penguinoids from being captured and mutated.";
    license = stdenv.lib.licenses.gpl2;
  };
}
