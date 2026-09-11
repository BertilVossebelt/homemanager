# ~/Dotfiles/flake.nix
{
  description = "AJ's home manager config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    # Add any AppImage or special packages here:
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
    in {
      homeConfigurations = {
        ajv = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs;
          modules = [
            ./modules/git-setup.nix
            ./modules/packages.nix
            ./modules/apps.nix
            ./modules/hyprland.nix
            ./modules/shell.nix
          ];
        };
      };
    };
}
