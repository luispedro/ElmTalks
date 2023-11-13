let
fixed_nixpkgs = builtins.fetchTarball {
      name = "nixpkgs-unstable-2023-09";
      url = "https://github.com/nixos/nixpkgs/archive/efcde1d6685d05db10e3bce06563d225cba90c48.tar.gz";
      sha256 = "1jq2yy1777pnzgf1dqxcpv04xvg9jm35cfar99yhzw9y2sc7cn43";
    };
in

{ nixpkgs ? fixed_nixpkgs,
  system ? builtins.currentSystem }:
with (import nixpkgs { inherit system; });

let
  mkDerivation =
    { srcs ? ./elm-srcs.nix
    , src
    , name
    , srcdir ? "./src"
    , registryDat ? ./registry.dat
    }:
    stdenv.mkDerivation {
      inherit name src;

      buildInputs = [ elmPackages.elm python3 ];

      buildPhase = pkgs.elmPackages.fetchElmDeps {
        elmPackages = import srcs;
        elmVersion = "0.19.1";
        inherit registryDat;
      };

      installPhase = ''
        elm make --optimize src/Main.elm --output $out/index.html
        cp -pir assets $out/

        python copy-Media-files.py $out/
      '';
    };

in mkDerivation {
  name = "lpc-slides";
  srcs = ./elm-srcs.nix;
  src = builtins.filterSource
            (path: _type: baseNameOf path != ".git" && baseNameOf path != "result")
            ./.;
  srcdir = "./src";
}

