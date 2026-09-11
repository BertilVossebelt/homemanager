# ~/Dotfiles/modules/apps/mako.nix
{ ... }:

{
  services.mako = {
    enable = true;
    settings = {
      background-color = "#1e1e2e";
      text-color = "#cdd6f4";
      border-color = "#89b4fa";
      border-radius = 8;
      border-size = 2;
      padding = "10,15";
      margin = "10";
      default-timeout = 5000;
      font = "JetBrainsMono Nerd Font 12";
    };
  };
}