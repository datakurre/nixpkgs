{ stdenv, python, fetchPypi, fetchurl, makeWrapper, unzip }:

let
  wheel_source = fetchPypi {
    pname = "wheel";
    version = "0.30.0";
    format = "wheel";
    sha256 = "e721e53864f084f956f40f96124a74da0631ac13fbbd1ba99e8e2b5e9cafdf64";
  };
  setuptools_source = fetchPypi {
    pname = "setuptools";
    version = "38.4.0";
    format = "wheel";
    sha256 = "155c2ec9fdcc00c3973d966b416e1cf3a1e7ce75f4c09fb760b23f94b935926e";
  };

  # TODO: Shouldn't be necessary anymore for pip > 9.0.1!
  # https://github.com/NixOS/nixpkgs/issues/26392
  # https://github.com/pypa/setuptools/issues/885
  pkg_resources = fetchurl {
    url = "https://raw.githubusercontent.com/pypa/setuptools/v36.2.5/pkg_resources/__init__.py";
    sha256 = "e8ebce4e2dd37bcdaadc35ad5248a5007ad01abbbd5b7f49c6a5564ae5b3ee72";
  };
  py31compat = fetchurl {
    url = "https://raw.githubusercontent.com/pypa/setuptools/v36.2.5/pkg_resources/py31compat.py";
    sha256 = "fb2b15aa8c4b7ad0272fde2e33490792898a4130b52592cdd99523a9484c78a1";
  };

in stdenv.mkDerivation rec {
  pname = "pip";
  version = "9.0.3";
  name = "${python.libPrefix}-bootstrapped-${pname}-${version}";

  src = fetchPypi {
    inherit pname version;
    format = "wheel";
    sha256 = "c3ede34530e0e0b2381e7363aded78e0c33291654937e7373032fda04e8803e5";
  };

  unpackPhase = ''
    mkdir -p $out/${python.sitePackages}
    unzip -d $out/${python.sitePackages} $src
    unzip -d $out/${python.sitePackages} ${setuptools_source}
    unzip -d $out/${python.sitePackages} ${wheel_source}
    # TODO: Shouldn't be necessary anymore for pip > 9.0.1!
    cp ${pkg_resources} $out/${python.sitePackages}/pip/_vendor/pkg_resources/__init__.py
    cp ${py31compat} $out/${python.sitePackages}/pip/_vendor/pkg_resources/py31compat.py
  '';

  patchPhase = ''
    mkdir -p $out/bin
  '';

  nativeBuildInputs = [ makeWrapper unzip ];
  buildInputs = [ python ];

  installPhase = ''

    # install pip binary
    echo '#!${python.interpreter}' > $out/bin/pip
    echo 'import sys;from pip import main' >> $out/bin/pip
    echo 'sys.exit(main())' >> $out/bin/pip
    chmod +x $out/bin/pip

    # wrap binaries with PYTHONPATH
    for f in $out/bin/*; do
      wrapProgram $f --prefix PYTHONPATH ":" $out/${python.sitePackages}/
    done
  '';
}
