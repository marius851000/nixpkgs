{ stdenv
, fetchFromGitHub
, haxePackages
, haxe
, neko
, SDL
, makeWrapper
, lib
, alsaLib
, libGL
, libpulseaudio
, libX11
, libXdmcp
, libXext
, libXi
, libXinerama
, libXrandr
, xdg-utils
, makeDesktopItem
}:

let
  dummy_api_file = builtins.toFile "APIStuff.hx" ''package;

class APIStuff
{
	public static var API:String = "";
	public static var EncKey:String = "";
}'';

  runtime_library = [
    alsaLib
    libGL
    libpulseaudio
    libX11
    libXdmcp
    libXext
    libXi
    libXinerama
    libXrandr
  ];
  
  desktopItem = makeDesktopItem {
    name = "funkin";
    desktopName = "Friday Night FUNKIN'";
    icon = "funkin";
    exec = "Funkin";
    categories = "Game";
  };
in
stdenv.mkDerivation rec {
  pname = "friday-night-funkin";
  version = "0.2.7.1";

  src = fetchFromGitHub {
    owner = "ninjamuffin99";
    repo = "Funkin";
    rev = "v${version}";
    sha256 = "sha256-ustwDGcqnp7ljvbb2xZeyZwJLaOzo62vFmG1TUbhV30=";
  };

  nativeBuildInputs = [ haxe neko haxePackages.lime makeWrapper ];

  buildInputs = with haxePackages; [
    hxcpp
    flixel
    flixel-addons
    flixel-ui
    newgrounds
    polymod
    hscript
  ];

  patchPhase = ''
    export dataDir=$out/share/friday-night-funkin
    cp ${dummy_api_file} source/APIStuff.hx
    substituteInPlace source/MainMenuState.hx \
        --replace /usr/bin/xdg-open ${xdg-utils}/bin/xdg-open
    substituteInPlace source/OutdatedSubState.hx \
        --replace "or ESCAPE to ignore this!!" "or ESCAPE to ignore this!!\n(you're using the unofficial nix packaged version)"
  '';

  configurePhase = ''
    export HOME=$(mktemp -d)
  '';

  buildPhase = ''
    haxelib run lime build linux -j$NIX_BUILD_CORES
  '';

  installPhase = ''
    mkdir -p $dataDir
    cp -r export/release/*/bin/* $dataDir
    chmod +x $dataDir/Funkin
    makeWrapper $dataDir/Funkin $out/bin/Funkin \
        --set LD_LIBRARY_PATH ${lib.makeLibraryPath runtime_library} \
        --run "cd $dataDir"


    mkdir -p $out/share/icons/hicolor/64x64/apps
    cp art/icon64.png $out/share/icons/hicolor/64x64/apps/funkin.png

    mkdir -p $out/share/applications
    cp ${desktopItem}/share/applications/* $out/share/applications
  '';

}
