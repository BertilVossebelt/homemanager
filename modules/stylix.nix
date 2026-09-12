# ~/Dotfiles/modules/stylix.nix
#
# Central theming. One base16 scheme (or a wallpaper) drives colours + fonts
# across GTK, Qt, the terminal, notifications, the lock screen, Hyprland borders,
# and — via colours injected into their own CSS — Waybar and the AGS control
# center (see modules/hyprland.nix and modules/ags.nix). Those two keep their
# hand-built layout; Stylix only recolours/refonts them.
#
# Toggle the colour source:
#   myStylix.mode = "scheme"    -> named base16 scheme in myStylix.scheme
#   myStylix.mode = "wallpaper" -> palette generated from myStylix.wallpaper
{ config, lib, pkgs, ... }:

let
  cfg = config.myStylix;
in
{
  options.myStylix = {
    mode = lib.mkOption {
      type = lib.types.enum [ "scheme" "wallpaper" ];
      default = "scheme";
      description = "Colour source: a named base16 scheme, or a wallpaper image.";
    };

    scheme = lib.mkOption {
      type = lib.types.str;
      default = "catppuccin-mocha";
      example = "gruvbox-dark-medium";
      description = ''
        base16 scheme name from the `base16-schemes` package (filename under
        its share/themes, without the `.yaml`). Used when mode = "scheme".
      '';
    };

    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression "./wallpaper.png";
      description = "Wallpaper image; also the colour source when mode = \"wallpaper\".";
    };

    polarity = lib.mkOption {
      type = lib.types.enum [ "either" "light" "dark" ];
      default = "dark";
      description = "Force a light or dark variant of the palette.";
    };
  };

  config = {
    # --- Active theme selection -----------------------------------------------
    # "Auto colors": the palette is generated from this wallpaper at build time.
    # To re-theme, drop in a new image here (or point at another path) and run
    # `hms`. Set mode = "scheme" to go back to a named base16 scheme instead.
    myStylix.mode = "wallpaper";
    myStylix.wallpaper = ./wallpapers/DSC_6696.jpg;

    assertions = [
      {
        assertion = cfg.mode == "scheme" || cfg.wallpaper != null;
        message = ''myStylix.mode = "wallpaper" requires myStylix.wallpaper to be set.'';
      }
    ];

    stylix = {
      enable = true;
      polarity = cfg.polarity;

      image = lib.mkIf (cfg.wallpaper != null) cfg.wallpaper;

      base16Scheme = lib.mkIf (cfg.mode == "scheme")
        "${pkgs.base16-schemes}/share/themes/${cfg.scheme}.yaml";

      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.jetbrains-mono;
          name = "JetBrainsMono Nerd Font Mono";
        };
        sansSerif = {
          package = pkgs.inter;
          name = "Inter";
        };
        serif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Serif";
        };
        emoji = {
          package = pkgs.noto-fonts-color-emoji;
          name = "Noto Color Emoji";
        };
      };

      # Targets we drive ourselves or that clash with the hand-built config:
      #  - waybar / hyprlock: their CSS/settings are hand-authored; we inject
      #    Stylix colours into them instead of letting Stylix restyle them.
      #  - qt: this setup uses the KDE platform theme (Dolphin etc.), which
      #    Stylix's qt target doesn't support.
      targets = {
        waybar.enable = false;
        hyprlock.enable = false;
        qt.enable = false;
      };
    };
  };
}
