# ~/Dotfiles/modules/shell.nix
{ lib, ... }:

{
  programs.bash = {
    enable = true;
    bashrcExtra = ''
      hms() {
        home-manager switch --flake ~/Dotfiles#''${1:-ajv}
      }
      sns() {
        sudo nixos-rebuild switch --flake /etc/nixos#''${1:-nixos-desktop}
      }
    '';
  };

  home.activation.reloadHyprland = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v hyprctl &>/dev/null; then
      $DRY_RUN_CMD hyprctl reload
    fi
  '';
}
