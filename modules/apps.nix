# ~/Dotfiles/modules/apps.nix
{ ... }:

{
  imports = [
    ./apps/ghostty.nix
    ./apps/theming.nix
    ./apps/mako.nix
    ./apps/hyprlock.nix
    ./apps/hypridle.nix
    ./apps/gammastep.nix
  ];
}