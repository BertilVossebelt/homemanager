# ~/Dotfiles/overlays/overlays.nix
self: super: {
  firefox-developer-edition = super.firefox.overrideAttrs (attrs: { });
  jetbrains-rider = super.jetbrains.rider;
  jetbrains-webstorm = super.jetbrains.webstorm;
  jetbrains-pycharm = super.jetbrains.pycharm;
  jetbrains-phpstorm = super.jetbrains.phpstorm;
  jetbrains-idea = super.jetbrains.idea;
  jetbrains-rustrover = super.rust-rover;
}
