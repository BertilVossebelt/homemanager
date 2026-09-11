# ~/Dotfiles/modules/apps/hypridle.nix
{ ... }:

{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "hyprlock";
        }
        {
          timeout = 600;
          on-timeout = "systemctl suspend";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };
}