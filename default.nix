let
fixed_nixpkgs = builtins.fetchTarball {
      name = "nixpks-unstable-2022-09";
      url = "https://github.com/nixos/nixpkgs/archive/3d6636ba27ca348f3f110d8fa6c9d7ae1fce648a.tar.gz";
      sha256 = "0dph11l5mgqlylhq86b0x3zg1n1vpy1j2f81b00l71j8qmwr3z8z";
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

      buildInputs = [ elmPackages.elm ];

      buildPhase = pkgs.elmPackages.fetchElmDeps {
        elmPackages = import srcs;
        elmVersion = "0.19.1";
        inherit registryDat;
      };

      installPhase = ''
        elm make --optimize src/Main.elm --output $out/index.html
        cp -pir Media $out/
        cp -pir assets $out/
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

