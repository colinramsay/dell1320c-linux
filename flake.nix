{
  description = "CUPS driver for the Dell 1320c color laser printer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    supportedSystems = [ "x86_64-linux" "i686-linux" ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in
  {
    packages = forAllSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        dell-1320c-driver = pkgs.callPackage ./nix/package.nix {};
        default = self.packages.${system}.dell-1320c-driver;
      }
    );

    nixosModules.dell-1320c = import ./nix/module.nix self;
    nixosModules.default = self.nixosModules.dell-1320c;
  };
}
