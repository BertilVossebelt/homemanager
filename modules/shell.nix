# ~/Dotfiles/modules/shell.nix
{ config, lib, ... }:

let
  c = config.lib.stylix.colors;
  # Truecolor SGR sequence from a Stylix base16 slot (e.g. "base0D").
  mkAnsi = base: "38;2;${c."${base}-rgb-r"};${c."${base}-rgb-g"};${c."${base}-rgb-b"}";
in
{
  programs.fastfetch = {
    enable = true;
    settings = {
      # Custom two-lambda NixOS logo. The file marks one lambda with $1 and the
      # other with $2; colours are pulled from Stylix so the logo recolours with
      # the active scheme. type = "file" (not "file-raw") so $N are resolved.
      logo = {
        type = "file";
        source = "${./fastfetch/nixos.txt}";
        color = {
          "1" = mkAnsi "base0D";  # accent lambda
          "2" = mkAnsi "base05";  # light foreground lambda
        };
        padding = {
          top = 1;
          left = 2;
        };
      };
      # A user config replaces fastfetch's default module set, so the info
      # blocks must be listed explicitly. Trimmed to the interesting ones.
      modules = [
        "title"
        "separator"
        "os"
        "kernel"
        "uptime"
        "wm"
        "shell"
        "terminal"
        "cpu"
        "gpu"
        "memory"
        "swap"
        "disk"
        "localip"
        "break"
        "colors"
      ];
    };
  };

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
    # Greet with system info, but only in interactive shells (keeps scripts /
    # scp / non-interactive `bash -c` output clean).
    initExtra = ''
      if [[ $- == *i* ]] && command -v fastfetch &>/dev/null; then
        fastfetch
      fi
    '';
  };

  home.activation.reloadHyprland = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v hyprctl &>/dev/null; then
      $DRY_RUN_CMD hyprctl reload
    fi
  '';
}
