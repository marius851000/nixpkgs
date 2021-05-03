{ stdenv, lib, fetchFromGitHub, fetchpatch
, haxe, haxePackages, neko, makeWrapper
, alsaLib, libpulseaudio, libGL, libX11, libXdmcp, libXext, libXi, libXinerama, libXrandr
}:

stdenv.mkDerivation rec {
  pname = "funkin";
  version = "unstable-2021-04-02";

  src = fetchFromGitHub {
    owner = "ninjamuffin99";
    repo = "Funkin";
    rev = "faaf064e37d5a150d8aba451d740eeb81bd2e974";
    sha256 = "053qbmib9nsgx63d0rcykky6284cixibrwq9rv1sqx2ghsdn78ff";
  };

  patches = [
    # TODO remove when fix pushed
    # Fixes Freeplay crash on master
    (fetchpatch {
      url = "https://github.com/ninjamuffin99/Funkin/pull/412/commits/af62bdca4d70e06ea8b383ab5c9c6b3f5d8f087b.patch";
      sha256 = "1p9vzm7hkay8fzrd82hgrnafd0g5qi34brzv0hyjirryhni840fy";
    })
  ];

  postPatch = ''
    # Real API keys are stripped from repo
    cat >source/APIStuff.hx <<EOF
    package;

    class APIStuff
    {
      public static var API:String = "";
      public static var EncKey:String = "";
    }
    EOF
  '';

  nativeBuildInputs = [ haxe neko makeWrapper ]
  ++ (with haxePackages; [
    hxcpp
    hscript
    openfl
    lime
    flixel
    flixel-addons
    flixel-ui
    newgrounds
    polymod
    discord_rpc
  ]);

  buildInputs = [ alsaLib libpulseaudio libGL libX11 libXdmcp libXext libXi libXinerama libXrandr ];

  enableParallelBuilding = true;

  buildPhase = ''
    runHook preBuild

    export HOME=$PWD
    export HXCPP_COMPILE_THREADS=${if enableParallelBuilding then "$NIX_BUILD_CORES" else "1"}
    haxelib run lime build linux -final

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib/funkin}
    cp -R export/release/linux/bin/* $out/lib/funkin/
    for so in $out/lib/funkin/{Funkin,lime.ndll}; do
      $STRIP -s $so
    done
    wrapProgram $out/lib/funkin/Funkin \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs} \
      --run "cd $out/lib/funkin"
    ln -s $out/{lib/funkin,bin}/Funkin

    runHook postInstall
  '';

  meta = with lib; {
    description = "Friday Night Funkin'";
    longDescription = ''
      Uh oh! Your tryin to kiss ur hot girlfriend, but her MEAN and EVIL dad is
      trying to KILL you! He's an ex-rockstar, the only way to get to his
      heart? The power of music...

      WASD/ARROW KEYS IS CONTROLS

      - and + are volume control

      0 to Mute

      It's basically like DDR, press arrow when arrow over other arrow.
      And uhhh don't die.
    '';
    homepage = "https://ninja-muffin24.itch.io/funkin";
    license = licenses.asl20;
    platforms = platforms.all;
    maintainers = with maintainers; [ OPNA2608 ];
    broken = stdenv.system != "x86_64-linux";
  };
}
