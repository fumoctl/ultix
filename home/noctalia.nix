{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    settings = {
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Catppuccin";
      };

      wallpaper = {
        enabled = true;
      };

      shell = {
        clipboard_enabled = true;
        clipboard_history_max_entries = 100;
        clipboard_keep_from_closed_apps = true;
        clipboard_auto_paste = "auto";
      };

      bar = {
        position = "top";
        widgets = {
          left = [
            "launcher"
            "workspaces"
            "active_window"
          ];
          center = [
            "clock"
            "media"
          ];
          right = [
            "tray"
            "clipboard"
            "volume"
            "network"
            "bluetooth"
            "battery"
            "control-center"
          ];
        };
      };
    };
  };
}
