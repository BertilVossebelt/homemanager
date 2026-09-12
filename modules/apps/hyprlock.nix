# ~/Dotfiles/modules/apps/hyprlock.nix
# Colours come from Stylix (stylix.targets.hyprlock is disabled so this keeps its
# screenshot-blur background and hand-set input-field geometry).
{ config, ... }:

let
  c = config.lib.stylix.colors.withHashtag;
in
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
        border_color = c.base0D;
        inner_color = c.base00;
        font_color = c.base05;
        placeholder_text = "";
      }];
    };
  };
}