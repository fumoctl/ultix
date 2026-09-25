{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
    ./hyprland.nix
    ./noctalia.nix
    ./shell.nix
  ];

  home.username = "fumoctl";
  home.homeDirectory = "/home/fumoctl";
  home.stateVersion = "26.05";

  # GNOME Keyring user service for the Hyprland session (wants
  # graphical-session-pre.target, wired up by the HM Hyprland module).
  # Explicit components so the daemon does NOT spawn its own SSH agent —
  # programs.gnupg.agent (enableSSHSupport) owns SSH_AUTH_SOCK.
  services.gnome-keyring = {
    enable = true;
    components = [
      "pkcs11"
      "secrets"
    ];
  };
}
