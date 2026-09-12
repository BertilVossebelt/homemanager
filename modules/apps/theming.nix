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

  # GTK apps: Stylix owns the theme/colours/font (see modules/stylix.nix).
  # We only keep the prefer-dark hints here; Stylix rejects gtk*.extraCss
  # (use stylix.targets.gtk.extraCss instead if extra CSS is ever needed).
  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  # GTK4 apps that respect color-scheme (e.g. libadwaita)
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
  };
}
