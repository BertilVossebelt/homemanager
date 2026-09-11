{ ... }:

{
  services.gammastep = {
    enable = true;
    provider = "manual";
    latitude = 52.57;
    longitude = 6.62;
    temperature = {
      day = 6000;
      night = 2800;
    };
    settings.general = {
      brightness-day = 1.0;
      brightness-night = 0.8;
    };
  };
}
