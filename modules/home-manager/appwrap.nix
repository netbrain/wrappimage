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

  mkDesktopEntry = name: app: wrapped:
    let
      binName = if app.binName != null then app.binName else name;
      execArgs = if app.desktop.execArgs != null then " " + app.desktop.execArgs else "";
      execPath = "${wrapped}/bin/${binName}" + execArgs;
      baseEntry = {
        name = if app.desktop.name != null then app.desktop.name else binName;
        exec = execPath;
        terminal = app.desktop.terminal;
        type = "Application";
        categories = app.desktop.categories;
      };
      withIcon = baseEntry // (optionalAttrs (app.desktop.icon != null) { icon = app.desktop.icon; });
      withComment = withIcon // (optionalAttrs (app.desktop.comment != null) { comment = app.desktop.comment; });
      withGenericName = withComment // (optionalAttrs (app.desktop.genericName != null) { genericName = app.desktop.genericName; });
      withKeywords = withGenericName // (optionalAttrs (app.desktop.keywords != []) { settings.Keywords = concatStringsSep ";" app.desktop.keywords + ";"; });
    in withKeywords;

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

          desktop = mkOption {
            description = "Desktop entry metadata for this application (to create a .desktop file).";
            default = {};
            type = types.submodule {
              options = {
                name = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = "Display name in menus (default: binName).";
                };
                genericName = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = "Generic name of the application.";
                };
                comment = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = "Short description used as tooltip.";
                };
                icon = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = "Icon name from theme or absolute path to icon file.";
                };
                categories = mkOption {
                  type = types.listOf types.str;
                  default = [ "Utility" ];
                  description = "Menu categories (e.g., [\"Utility\", \"Network\"]).";
                };
                terminal = mkOption {
                  type = types.bool;
                  default = false;
                  description = "Whether to run in a terminal.";
                };
                execArgs = mkOption {
                  type = types.nullOr types.str;
                  default = "%U";
                  description = "Arguments placeholder appended to Exec (e.g., %U or %F). Set null to omit.";
                };
                keywords = mkOption {
                  type = types.listOf types.str;
                  default = [];
                  description = "Keywords (search terms) for desktop entry.";
                };
              };
            };
          };
        };
      }));
      default = {};
      description = "Map of app names to AppImage definitions.";
    };
  };

  config = mkIf cfg.enable (
    let
      appPkgs = mapAttrs (n: v: mkPkg n v) cfg.apps;
      desktopEntries = mapAttrs (n: v: mkDesktopEntry n v (appPkgs.${n})) cfg.apps;
    in {
      home.packages = attrValues appPkgs;
      xdg.desktopEntries = desktopEntries;
    }
  );
}
