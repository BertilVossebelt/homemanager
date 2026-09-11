# ~/Dotfiles/modules/apps/theming.nix
{ pkgs, ... }:

{
  # Qt apps (Dolphin, KSysGuard, etc.) use KDE platform theme → reads kdeglobals dark mode
  qt = {
    enable = true;
    platformTheme.name = "kde";
  };

  # Walker launches apps via GLib/systemd transient units which inherit the systemd user
  # environment, not Hyprland's env= vars — so Qt theme vars must live here too
  systemd.user.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "kde";
    QT_QPA_PLATFORM = "wayland";
    ADW_DEBUG_COLOR_SCHEME = "prefer-dark";
  };

  # GTK apps: prefer dark via settings.ini (no portal needed)
  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4 = {
      extraConfig.gtk-application-prefer-dark-theme = true;
      extraCss = ''
        @import 'colors.css';
      '';
    };
  };

  # GTK4 apps that respect color-scheme (e.g. libadwaita)
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
  };
}
