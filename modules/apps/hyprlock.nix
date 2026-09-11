# ~/Dotfiles/modules/apps/hyprlock.nix
{ ... }:

{
  programs.hyprlock = {
    enable = true;
    settings = {
      background = [{
        monitor = "";
        path = "screenshot";
        blur_passes = 3;
        blur_size = 7;
      }];

      input-field = [{
        monitor = "";
        size = "300, 50";
        position = "0, -80";
        halign = "center";
        valign = "center";
        border_color = "#89b4fa";
        inner_color = "#1e1e2e";
        font_color = "#cdd6f4";
        placeholder_text = "";
      }];
    };
  };
}