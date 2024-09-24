{
  description = "Experiments to install libsass 0.12.3";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
    flake-utils.url = "github:numtide/flake-utils";
    wkhtmltopdf-flake.url = "github:iledarn/wkhtmltopodfnix";
  };

  outputs = { self, nixpkgs, flake-utils, wkhtmltopdf-flake }:
  flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = nixpkgs.legacyPackages.${system};

    gitaggregator = pkgs.python37Packages.buildPythonPackage rec {
      pname = "git-aggregator";
      version = "4.0.1";
      format = "wheel";  # Specify that this is a wheel

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/d3/39/7849f5b08226e4085de37a95095482475a7d3811ee7e736e9ce7cb9f2a45/git_aggregator-4.0.1-py3-none-any.whl";
        sha256 = "e4f6cbe6a1b6adda9c8d6838bd2248a42f189769e4eac4f724537e86b997aee4"; # Replace with actual hash
      };

      doCheck = false;  # Skip tests if they're causing issues
      propagatedBuildInputs = with pkgs.python37Packages; [
        pyyaml
        argcomplete
        colorama
        requests
      ];
    };

    libsass-python = pkgs.python37Packages.buildPythonPackage rec {
      pname = "libsass";
      version = "0.15.0";
      format = "wheel";  # Specify that this is a wheel

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/56/48/b4e0309c15c92936250eaf069a63c69ab863bba3d30075fbfe323ce4531f/libsass-0.15.0-cp37-cp37m-manylinux1_x86_64.whl";
        sha256 = "d7eef002cada7533edae40fac1fbeb23b14d56c51683d695c93860b4d5cd7b67";
      };

      doCheck = false;  # Skip tests if they're causing issues

      propagatedBuildInputs = with pkgs.python37Packages; [
        six
      ];

    };

    pythonEnv = pkgs.python37.withPackages (ps: with ps; [
      gitaggregator
      libsass-python
      requests
      Babel
      pypdf2
      passlib
      werkzeug
      lxml
      decorator
      dateutil
      psycopg2
      pillow
      setuptools
      psutil
      jinja2
      reportlab
      html2text
      docutils
      num2words
      xlrd
      cachetools
      XlsxWriter
      markdown
      google-auth
      google-auth-oauthlib
      google-api-python-client
      beautifulsoup4
      jira
      numpy
      xlwt
      phonenumbers
      gevent

    ]);

    wkhtmltopdf = wkhtmltopdf-flake.packages.${system}.default;


    myEnv = pkgs.buildEnv {
      name = "my-python-env-3-7-11";
      paths = with pkgs; [
        pythonEnv
        stdenv.cc.cc.lib
        wkhtmltopdf
        postgresql_13
      ];
    };

    wrapperScript = pkgs.writeScriptBin "python-with-libs" ''
      #!${pkgs.stdenv.shell}
      export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH
      exec ${pythonEnv}/bin/python "$@"
    '';
  in
  {
    packages = {
      default = myEnv;
      python-with-libs = wrapperScript;
    };

    apps = {
      default = {
        type = "app";
        program = "${wrapperScript}/bin/python-with-libs";
      };
      python-with-libs = {
        type = "app";
        program = "${wrapperScript}/bin/python-with-libs";
      };
    };

    devShell = pkgs.mkShell {
      buildInputs = [ myEnv wrapperScript ];
      shellHook = ''
        export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH
      '';
    };
  }
  );
}
