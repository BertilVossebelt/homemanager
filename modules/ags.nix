# ~/Dotfiles/modules/ags.nix
# Astal/AGS widget shell — left-edge control center + (later) calendar.
{ config, pkgs, inputs, ... }:

let
  agsPkgs = inputs.ags.packages.${pkgs.system};
in
{
  programs.ags = {
    enable = true;
    configDir = ./ags;
    # Auto-start `ags run` as a graphical-session user service. With `ags/gtk3`
    # imports the GTK version is inferred, so no extra flags are needed.
    systemd.enable = true;
    # Astal service bindings the widgets consume at runtime.
    extraPackages = [
      agsPkgs.network
      agsPkgs.bluetooth
      agsPkgs.wireplumber
      agsPkgs.mpris
      agsPkgs.tray
    ];
  };

  # (The programs.ags module already manages ~/.local/share/ags — the JS library
  # that `ags/*` and `gnim` imports resolve against — so no manual symlink here.)

  # CLIs the widgets shell out to for actions (toggles, etc.).
  home.packages = with pkgs; [
    networkmanager
    wireplumber
  ];
}
