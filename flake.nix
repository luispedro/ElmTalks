{
  description = "LPC presentation";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/3d6636ba27ca348f3f110d8fa6c9d7ae1fce648a";
  outputs = { self, nixpkgs }:
  let system = "x86_64-linux";
  in {

        packages.x86_64-linux.presentation = (import ./default.nix) { inherit nixpkgs system; };

        defaultPackage.x86_64-linux = self.packages.x86_64-linux.presentation;
      };
}
