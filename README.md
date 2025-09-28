# wrappimage: Declarative AppImage wrappers for Home Manager

This flake provides a Home Manager module that creates wrapper binaries in your PATH using nixpkgs' built-in appimageTools.wrapType2. Each wrapper runs the AppImage from the Nix store, fetched reproducibly via pkgs.fetchurl (content-addressed by hash).

Why appimageTools?
- Uses the official nixpkgs AppImage tooling (no ad-hoc curl/wget wrappers).
- Reproducible: AppImages are fetched into the Nix store via pkgs.fetchurl using a sha256 hash.
- No runtime network: Downloads happen at build time; wrappers do not fetch on first run.

Prerequisites
- Nix with flakes enabled
- Home Manager (flake integration)

Quick start
1) Add this flake as an input and import the Home Manager module.
2) Declare your AppImages with URL and hash.

Example flake usage (home-manager):

```nix path=null start=null
{
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
                url = "https://app.warp.dev/get_warp?package=appimage";
                # Replace with a real hash for the URL above (SRI or base32)
                hash = "sha256-REPLACE_ME";
                binName = "warp-terminal";
                # optional: extra runtime libs
                # extraPkgs = with pkgs; [ libsecret gtk3 ];
                # optional: source a profile snippet before running
                # profile = '' export MY_FLAG=1 '';
              };
            };
          }
        ];
      };
    };
}
```

Computing the hash (SRI recommended):
- Preferred (Nix 2.21+):
  nix store prefetch-file --hash-type sha256 --json "https://example.com/MyApp.AppImage" | jq -r .hash
- Alternatively (older tooling):
  nix-prefetch-url --type sha256 "https://example.com/MyApp.AppImage"
  # Then convert to SRI if desired:
  nix hash to-sri --type sha256 $(nix-prefetch-url --type sha256 "https://example.com/MyApp.AppImage")

Notes
- If the upstream URL is mutable (e.g., .../latest.AppImage), the hash will change when they publish a new build. Update the hash in your config to pick up the new version.
- The wrapper name defaults to the attribute name, but you can set binName to customize it.
- extraPkgs lets you add runtime libraries the AppImage expects.
