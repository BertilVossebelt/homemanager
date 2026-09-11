# ~/Dotfiles/modules/hyprland.nix
{ pkgs, ... }:

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
    "waybar/style.css".source    = ./waybar/style.css;

    "walker/config.toml".source                        = ./walker/config.toml;
    "walker/themes/monochrome/monochrome.toml".source  = ./walker/themes/monochrome/monochrome.toml;
    "walker/themes/monochrome/style.css".source        = ./walker/themes/monochrome/style.css;
    "walker/themes/monochrome/layout.xml".source       = ./walker/themes/monochrome/layout.xml;
    "walker/themes/monochrome/keybind.xml".source      = ./walker/themes/monochrome/keybind.xml;
  };

  programs.waybar.enable = true;

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