{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  name = "makerom-${version}";
  version = "0.15";

  src = fetchFromGitHub {
    owner = "profi200";
    repo = "Project_CTR";
    rev = version;
    sha256 = "1l6z05x18s1crvb283yvynlwsrpa1pdx1nbijp99plw06p88h4va";
  };

  builder = ./builder.sh;

  nativeBuildInputs = [];
}
