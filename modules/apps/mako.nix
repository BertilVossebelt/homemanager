# ~/Dotfiles/modules/apps/mako.nix
{ ... }:

{
  # Colours and font come from Stylix; only shape/behaviour is set here.
  services.mako = {
    enable = true;
    settings = {
      border-radius = 8;
      border-size = 2;
      padding = "10,15";
      margin = "10";
      default-timeout = 5000;
    };
  };
}