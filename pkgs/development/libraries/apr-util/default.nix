{ lib, stdenv, fetchurl, makeWrapper, apr, expat, gnused
, sslSupport ? true, openssl
, bdbSupport ? true, db
, ldapSupport ? !stdenv.isCygwin, openldap
, libiconv
, cyrus_sasl, autoreconfHook
}:

assert sslSupport -> openssl != null;
assert bdbSupport -> db != null;
assert ldapSupport -> openldap != null;

with lib;

let
  db_version_lib = let
    # if the db package add a version field, use it
    db_version = lib.elemAt (lib.splitString "-" db.name) 1;
    db_version_splited = lib.splitString "." db_version;
  in
    (lib.elemAt db_version_splited 0) + (lib.elemAt db_version_splited 1);
in
stdenv.mkDerivation rec {
  name = "apr-util-1.6.1";

  src = fetchurl {
    url = "mirror://apache/apr/${name}.tar.bz2";
    sha256 = "0nq3s1yn13vplgl6qfm09f7n0wm08malff9s59bqf9nid9xjzqfk";
  };

  patches = optional stdenv.isFreeBSD ./include-static-dependencies.patch;

  # The script have issue finding the good version when cross-compiling
  postPatch = if bdbSupport then ''
    substituteInPlace configure \
      --replace db_version=69 db_version=${db_version_lib}
  '' else "";

  outputs = [ "out" "dev" ];
  outputBin = "dev";

  buildInputs = optional stdenv.isFreeBSD autoreconfHook;

  configureFlags = [ "--with-apr=${apr.dev}" "--with-expat=${expat.dev}" ]
    ++ optional (!stdenv.isCygwin) "--with-crypto"
    ++ optional sslSupport "--with-openssl=${openssl.dev}"
    ++ optional bdbSupport "--with-berkeley-db=${db.dev}"
    ++ optional ldapSupport "--with-ldap=ldap"
    ++ optionals stdenv.isCygwin
      [ "--without-pgsql" "--without-sqlite2" "--without-sqlite3"
        "--without-freetds" "--without-berkeley-db" "--without-crypto" ]
    ;

  propagatedBuildInputs = [ apr expat libiconv ]
    ++ optional sslSupport openssl
    ++ optional bdbSupport db
    ++ optional ldapSupport openldap
    ++ optional stdenv.isFreeBSD cyrus_sasl;
  
  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    for f in $out/lib/*.la $out/lib/apr-util-1/*.la $dev/bin/apu-1-config; do
      substituteInPlace $f \
        --replace "${expat.dev}/lib" "${expat.out}/lib" \
        --replace "${db.dev}/lib" "${db.out}/lib" \
        --replace "${openssl.dev}/lib" "${openssl.out}/lib"
    done

    # Give apr1 access to sed for runtime invocations.
    wrapProgram $dev/bin/apu-1-config --prefix PATH : "${gnused}/bin"
  '';

  enableParallelBuilding = true;

  passthru = {
    inherit sslSupport bdbSupport ldapSupport;
  };

  meta = with lib; {
    homepage = "http://apr.apache.org/";
    description = "A companion library to APR, the Apache Portable Runtime";
    maintainers = [ maintainers.eelco ];
    platforms = platforms.unix;
    license = licenses.asl20;
  };
}
