{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.programs.wrappimage;

  mkPkg = name: app:
    let
      binName = if app.binName != null then app.binName else name;
      src = pkgs.fetchurl {
        url = app.url;
        hash = app.hash; # Accept SRI or Nix base32
      };
      wrapped = pkgs.appimageTools.wrapType2 {
        pname = binName;
        version = app.version;
        inherit src;
        # Convert list to the function form expected by wrapType2
        extraPkgs = pkgs': app.extraPkgs;
        profile = app.profile;
      };
    in wrapped;

in {
  options.programs.wrappimage = {
    enable = mkEnableOption "Declarative AppImage wrappers via appimageTools.wrapType2 (reproducible)";

    apps = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          url = mkOption {
            type = types.str;
            description = "Remote URL to the AppImage file.";
            example = "https://app.warp.dev/get_warp?package=appimage";
          };
          hash = mkOption {
            type = types.str;
            description = "Content hash for pkgs.fetchurl (sha256 in SRI or base32).";
            example = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          };
          binName = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Name of the wrapper binary to install (defaults to attribute name).";
          };
          version = mkOption {
            type = types.str;
            default = "latest";
            description = "Version label passed to appimageTools (useful for reproducibility and metadata).";
          };
          extraPkgs = mkOption {
            type = types.listOf types.package;
            default = [];
            description = "Extra runtime packages needed by the AppImage (e.g., GTK/Qt libs).";
          };
          profile = mkOption {
            type = types.str;
            default = "";
            description = "Shell snippet sourced by the wrapper (e.g., export env vars).";
          };
        };
      }));
      default = {};
      description = "Map of app names to AppImage definitions.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = mapAttrsToList (n: v: mkPkg n v) cfg.apps;
  };
}
