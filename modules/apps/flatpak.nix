# ~/Dotfiles/modules/apps/flatpak.nix
# Declarative per-user Flatpak apps via nix-flatpak. The Flatpak runtime itself
# is enabled at the system level (/etc/nixos → services.flatpak.enable); this
# only declares which apps to install for this user and keeps them up to date.
# Find app IDs at https://flathub.org.
{ ... }:

{
  services.flatpak = {
    remotes = [
      {
        name = "flathub";
        location = "https://flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    packages = [
      # "com.brave.Browser"
      # "md.obsidian.Obsidian"
    ];

    # Reconcile installed apps with this list on each `home-manager switch`.
    update.onActivation = true;
  };
}
