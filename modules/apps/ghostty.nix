# ~/Dotfiles/modules/ghostty.nix
{ pkgs, ... }:

{
  programs.ghostty = {
    enable = true;
    settings = {
      font-size = 13;
      window-decoration = false;
      keybind = [
        "performable:ctrl+c=copy_to_clipboard"
        "ctrl+v=paste_from_clipboard"
      ];
    };
  };
}