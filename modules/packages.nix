# ~/Dotfiles/modules/packages.nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    firefox-devedition
    xdg-desktop-portal-gtk
    signal-desktop
    slack
    steam
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
    gsimplecal
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
