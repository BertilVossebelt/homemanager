# ~/Dotfiles/modules/packages.nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    xdg-desktop-portal-gtk
    signal-desktop
    slack
    obsidian
    rapidraw
    tidal-hifi
    zapzap
    jetbrains.rider
    jetbrains.webstorm
    jetbrains.pycharm
    jetbrains.phpstorm
    jetbrains.idea
    jetbrains.rust-rover
    claude-code

    # Hyprland tools
    networkmanagerapplet   # nm-connection-editor (network settings GUI)
    brightnessctl          # backlight control (AGS brightness slider)
    awww
    waypaper
    walker
    elephant
    fd
    grimblast
    pwvucontrol
    wl-clipboard
    hyprpolkitagent
    nerd-fonts.jetbrains-mono
    inter
  ];
}
