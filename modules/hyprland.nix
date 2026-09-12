# ~/Dotfiles/modules/hyprland.nix
{ config, pkgs, ... }:

let
  # Waybar keeps its hand-built layout; only colours + font are swapped in from
  # Stylix (its own waybar target is disabled in modules/stylix.nix).
  c = config.lib.stylix.colors.withHashtag;
  waybarStyle = builtins.replaceStrings
    [ "__BASE00__" "__BASE05__" "__BASE0D__" "__FONT__" ]
    [ c.base00 c.base05 c.base0D config.stylix.fonts.monospace.name ]
    (builtins.readFile ./waybar/style.css);
  # Walker uses the sans (UI) font rather than the monospace one.
  walkerStyle = builtins.replaceStrings
    [ "__BASE00__" "__BASE05__" "__BASE0D__" "__FONT__" ]
    [ c.base00 c.base05 c.base0D config.stylix.fonts.sansSerif.name ]
    (builtins.readFile ./walker/themes/monochrome/style.css);
in
{
  systemd.user.services.elephant = {
    Unit = {
      Description = "Elephant app indexer for Walker";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.elephant}/bin/elephant";
      # elephant's `files` provider indexes by shelling out to `fd`, and it
      # execs the apps walker launches — so PATH must include the home-manager
      # profile (where firefox-devedition et al. live), not just fd + system.
      Environment = [ "PATH=%h/.nix-profile/bin:${pkgs.fd}/bin:/run/current-system/sw/bin" ];
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.walker-daemon = {
    Unit = {
      Description = "Walker launcher GApplication service";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" "elephant.service" ];
    };
    Service = {
      ExecStart = "${pkgs.walker}/bin/walker --gapplication-service";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    # The compositor comes from the NixOS module (programs.hyprland.enable in
    # /etc/nixos/modules/system/desktop-hyprland.nix) — that is what SDDM launches.
    # null here stops home-manager installing a SECOND Hyprland from its own
    # (unstable) nixpkgs, which adds a duplicate SDDM session entry and puts a
    # mismatched hyprctl/portal on PATH. Home-manager manages the config only.
    package = null;
    portalPackage = null;
    configType = "hyprlang";
    extraConfig = ''
      source = ~/.config/hypr/monitors.conf
      source = ~/.config/hypr/env.conf
      source = ~/.config/hypr/input.conf
      source = ~/.config/hypr/appearance.conf
      source = ~/.config/hypr/autostart.conf
      source = ~/.config/hypr/binds.conf
    '';
  };

  xdg.configFile = {
    "hypr/monitors.conf".source   = ./hypr/monitors.conf;
    "hypr/env.conf".source        = ./hypr/env.conf;
    "hypr/input.conf".source      = ./hypr/input.conf;
    "hypr/appearance.conf".source = ./hypr/appearance.conf;
    "hypr/autostart.conf".source  = ./hypr/autostart.conf;
    "hypr/binds.conf".source      = ./hypr/binds.conf;

    "waybar/config.jsonc".source = ./waybar/config.jsonc;
    "waybar/style.css".text      = waybarStyle;
    "waybar/clock.sh" = {
      source = ./waybar/clock.sh;
      executable = true;
    };

    "elephant/desktopapplications.toml".source = ./elephant/desktopapplications.toml;

    "walker/config.toml".source                        = ./walker/config.toml;
    "walker/themes/monochrome/monochrome.toml".source  = ./walker/themes/monochrome/monochrome.toml;
    "walker/themes/monochrome/style.css".text          = walkerStyle;
    "walker/themes/monochrome/layout.xml".source       = ./walker/themes/monochrome/layout.xml;
    "walker/themes/monochrome/keybind.xml".source      = ./walker/themes/monochrome/keybind.xml;
  };

  programs.waybar = {
    enable = true;
    # Run waybar as a graphical-session user service so it restarts on failure
    # and survives system rebuilds that churn user units (exec-once only fires
    # at Hyprland startup).
    systemd.enable = true;
  };

  # Waybar reads style.css at startup and HM only restarts a service when its
  # unit text changes — so embed the themed CSS as a restart trigger. A colour
  # change alters this path, changing the unit, so `home-manager switch`
  # restarts waybar and the new theme takes effect without a manual restart.
  systemd.user.services.waybar.Unit.X-Restart-Triggers =
    [ (pkgs.writeText "waybar-style.css" waybarStyle) ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html"                    = "firefox-devedition.desktop";
      "x-scheme-handler/http"        = "firefox-devedition.desktop";
      "x-scheme-handler/https"       = "firefox-devedition.desktop";
      "x-scheme-handler/ftp"         = "firefox-devedition.desktop";
      "x-scheme-handler/sgnl"        = "signal.desktop";
      "x-scheme-handler/signalcaptcha" = "signal.desktop";
      "x-scheme-handler/upnote"      = "UpNote.desktop";
      "x-scheme-handler/claude-cli"  = "claude-code-url-handler.desktop";
      "x-scheme-handler/jetbrains"   = "jetbrainsd.desktop";
      "x-scheme-handler/slack"       = "slack.desktop";
    };
  };
}