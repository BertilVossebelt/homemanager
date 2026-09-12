# ~/Dotfiles/modules/ags.nix
# Astal/AGS widget shell — left-edge control center + (later) calendar.
{ config, pkgs, inputs, ... }:

let
  agsPkgs = inputs.ags.packages.${pkgs.system};

  # The panel keeps its hand-built layout; only colours + font are swapped in
  # from Stylix. AGS bundles ./ags at build time, so we hand it a copy of the
  # dir with style.scss's Stylix tokens substituted (AGS has no Stylix target).
  c = config.lib.stylix.colors.withHashtag;
  themedStyle = builtins.replaceStrings
    [ "__BASE00__" "__BASE05__" "__BASE0D__" "__FONT__" ]
    [ c.base00 c.base05 c.base0D config.stylix.fonts.monospace.name ]
    (builtins.readFile ./ags/style.scss);
  agsConfigDir = pkgs.runCommandLocal "ags-config" { } ''
    cp -r ${./ags} $out
    chmod -R u+w $out
    cp ${pkgs.writeText "style.scss" themedStyle} $out/style.scss
  '';
in
{
  programs.ags = {
    enable = true;
    configDir = agsConfigDir;
    # Auto-start `ags run` as a graphical-session user service. With `ags/gtk3`
    # imports the GTK version is inferred, so no extra flags are needed.
    systemd.enable = true;
    # Astal service bindings the widgets consume at runtime.
    extraPackages = [
      agsPkgs.network
      agsPkgs.bluetooth
      agsPkgs.wireplumber
      agsPkgs.mpris
      agsPkgs.tray
    ];
  };

  # AGS loads its (compiled) style once at startup, and HM only restarts a
  # service when its unit text changes — so tie the service to the themed config
  # dir. A colour change alters this path, so `home-manager switch` restarts AGS
  # and the new theme applies without a manual restart.
  systemd.user.services.ags.Unit.X-Restart-Triggers = [ agsConfigDir ];

  # (The programs.ags module already manages ~/.local/share/ags — the JS library
  # that `ags/*` and `gnim` imports resolve against — so no manual symlink here.)

  # CLIs the widgets shell out to for actions (toggles, etc.).
  home.packages = with pkgs; [
    networkmanager
    wireplumber
  ];
}
