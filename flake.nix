{
  description = "wrappimage: Declarative AppImage wrappers for Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
    in {
      homeModules.wrappimage = import ./modules/home-manager/appwrap.nix;

      packages = forAllSystems (pkgs: {
        default = pkgs.writeShellApplication {
          name = "wrappimage";
          runtimeInputs = with pkgs; [ coreutils curl wget appimage-run ];
          text = ''
            cat <<'EOH'
wrappimage is intended to be used declaratively via its Home Manager module.

Quick start (flake):
- Add this flake as an input
- Import homeModules.wrappimage in your Home Manager config
- Set programs.wrappimage.enable = true;
- Define programs.wrappimage.apps = { ... };
EOH
          '';
        };
      });

      overlays.default = final: prev: {
        wrappimage = self.packages.${final.system}.default;
      };
    };
}
