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

stdenv.mkDerivation {
  name = "lpc-slides";
  srcs = ./.;
  buildInputs = [ netlify-cli ];

}

