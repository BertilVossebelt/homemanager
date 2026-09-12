# ~/Dotfiles/flake.nix
{
  description = "AJ's home manager config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    # Astal/AGS widget shell (control center, calendar, ...).
    # The ags flake also re-exposes the astal service libs at matching versions,
    # so no separate astal input is needed.
    ags.url = "github:aylur/ags";
    ags.inputs.nixpkgs.follows = "nixpkgs";
    # Add any AppImage or special packages here:
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs:
    let
      system = "x86_64-linux";

      # Walker chooses a file preview by EXTENSION only (new_mime_guess), so
      # plain-text formats it doesn't know (.nix, .rs, .sh, ...) fall through to
      # the generic "no content" preview. This overlay patches Walker's source to
      # force a curated set of known-text extensions through the text preview.
      # `--replace-fail` makes a future Walker bump that moves this anchor line
      # fail the build loudly, rather than silently dropping the patch.
      walkerTextPreview = final: prev: {
        walker = prev.walker.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace src/preview/mod.rs \
              --replace-fail \
              'let Some(guess) = new_mime_guess::from_path(file_path).first() else {' \
              'if let Some(__ext) = Path::new(file_path).extension().and_then(|e| e.to_str()).map(|e| e.to_ascii_lowercase()) { const TEXT_EXTS: &[&str] = &["nix","rs","toml","lock","conf","cfg","ini","kdl","ron","scm","el","lua","vim","zig","nu","fish","sh","bash","zsh","tf","hcl","tfvars","just","mk","pp","sops","properties","yaml","yml","json","jsonc"]; if TEXT_EXTS.contains(&__ext.as_str()) { return self.preview_text_file(file_path); } } let Some(guess) = new_mime_guess::from_path(file_path).first() else {'
          '';
        });
      };

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ walkerTextPreview ];
      };
    in {
      homeConfigurations = {
        ajv = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs;
          extraSpecialArgs = { inherit inputs; };
          modules = [
            inputs.ags.homeManagerModules.default
            ./modules/git-setup.nix
            ./modules/packages.nix
            ./modules/apps.nix
            ./modules/hyprland.nix
            ./modules/ags.nix
            ./modules/shell.nix
          ];
        };
      };
    };
}
