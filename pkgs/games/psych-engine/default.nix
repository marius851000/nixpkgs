{ stdenv, lib, fetchFromGitHub, fetchpatch
, haxe, haxePackages, neko, makeWrapper, imagemagick
, alsa-lib, libpulseaudio, libGL, libX11, libXdmcp, libXext, libXi, libXinerama, libXrandr, luajit
, makeDesktopItem
}:

let
  #TODO: adapt for psych engine
  desktopItem = makeDesktopItem {
    name = "funkin";
    exec = "Funkin";
    desktopName = "Friday Night Funkin";
    categories = ["Game" "ArcadeGame"];
    icon = "funkin";
  };
in
stdenv.mkDerivation rec {
  pname = "psych-engine";
  version = "0.5.1";

  src = fetchFromGitHub {
    owner = "ShadowMario";
    repo = "FNF-PsychEngine";
    rev = version;
    sha256 = "sha256-QG515Se/wBt0a3oBDF4VjD8BZrjhZjZ0Zifkwe39Yi8=";
  };

  nativeBuildInputs = [ haxe neko makeWrapper imagemagick ]
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
    linc_luajit
  ]);

  buildInputs = [ alsa-lib libpulseaudio libGL libX11 libXdmcp libXext libXi libXinerama libXrandr luajit  ];

  enableParallelBuilding = true;

  buildPhase = ''
    runHook preBuild

    export HOME=$PWD
    haxelib run lime build linux -final

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib/psych-engine}
    cp -R export/release/linux/bin/* $out/lib/psych-engine/
    for so in $out/lib/psych-engine/{PsychEngine,lime.ndll}; do
      $STRIP -s $so
    done
    wrapProgram $out/lib/psych-engine/PsychEngine \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs} \
      --run "cd $out/lib/psych-engine"
    ln -s $out/{lib/psych-engine,bin}/PsychEngine
    # desktop file
    mkdir -p $out/share/applications
    ln -s ${desktopItem}/share/applications/* $out/share/applications

    # icons
    for i in 16 32 64; do
      install -D art/icon$i.png $out/share/icons/hicolor/''${i}x$i/PsychEngine.png
    done

    runHook postInstall
  '';

  #TODO: meta
}
