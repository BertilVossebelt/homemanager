# ~/Dotfiles/modules/shell.nix
{ config, lib, pkgs, ... }:

let
  c = config.lib.stylix.colors;
  # Truecolor SGR sequence from a Stylix base16 slot (e.g. "base0D").
  mkAnsi = base: "38;2;${c."${base}-rgb-r"};${c."${base}-rgb-g"};${c."${base}-rgb-b"}";

  # Turn a plain art file into a fastfetch logo: '*'/'+' -> colour 1, '-' ->
  # colour 2. Edit fastfetch/nixos-art.txt in raw *, +, - and spaces; this
  # inserts the $N codes automatically so no hand-coding is needed.
  logoColored = builtins.replaceStrings
    [ "*" "+" "-" ] [ "$1*" "$1+" "$2-" ]
    (builtins.readFile ./fastfetch/nixos-art.txt);
  logoFile = pkgs.writeText "nixos-logo" logoColored;
in
{
  programs.fastfetch = {
    enable = true;
    settings = {
      # Custom two-lambda NixOS logo generated from nixos-art.txt (above).
      # Colours come from Stylix so the logo recolours with the active scheme.
      logo = {
        type = "file";
        source = "${logoFile}";
        color = {
          "1" = mkAnsi "base0D";  # * / + lambda (accent)
          "2" = mkAnsi "base05";  # - lambda (light foreground)
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
