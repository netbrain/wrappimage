{
  description = "appwrap example: warp-terminal via AppImage";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    wrappimage.url = "github:netbrain/wrappimage";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, wrappimage, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      homeConfigurations.netbrain = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          wrappimage.homeModules.wrappimage
          {
            programs.wrappimage = {
              enable = true;
              apps.warp-terminal = {
          url = "https://releases.warp.dev/stable/v0.2025.09.24.08.11.stable_00/Warp-x86_64.AppImage";
          hash = "sha256-PrV7FIMkWE+5vl43uxmwWDhQZi6ynrtR+bQ2gYlpm0U=";
          binName = "warp-terminal";
              };
            };
          }
        ];
      };

      packages.${system} = let
        warp = pkgs.appimageTools.wrapType2 {
          pname = "warp-terminal";
          version = "v0.2025.09.24.08.11.stable_00";
          src = pkgs.fetchurl {
            url = "https://releases.warp.dev/stable/v0.2025.09.24.08.11.stable_00/Warp-x86_64.AppImage";
            hash = "sha256-PrV7FIMkWE+5vl43uxmwWDhQZi6ynrtR+bQ2gYlpm0U=";
          };
        };
      in {
        warp-terminal = warp;
        default = warp;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [ self.packages.${system}.warp-terminal ];
      };
    };
}
