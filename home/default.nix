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
}
