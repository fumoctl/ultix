{
  config,
  lib,
  pkgs,
  ...
}:

{
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      "$mainMod" = "SUPER";
      "$terminal" = "ptyxis";
      "$fileManager" = "nautilus";

      # Autostart Noctalia desktop shell & export session environment
      "exec-once" = [
        "noctalia"
        "systemctl --user import-environment PATH WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
      ];

      monitor = [
        ",preferred,auto,1"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(89b4faee) rgba(cba6f7ee) 45deg";
        "col.inactive_border" = "rgba(585b70aa)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 12;
        blur = {
          enabled = true;
          size = 4;
          passes = 2;
          new_optimizations = true;
          vibrancy = 0.1696;
        };
        shadow = {
          enabled = true;
          range = 8;
          render_power = 2;
          color = "rgba(1a1a1aee)";
        };
      };

      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 5, myBezier"
          "windowsOut, 1, 5, default, popin 80%"
          "border, 1, 8, default"
          "fade, 1, 5, default"
          "workspaces, 1, 4, default"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
      };

      bind = [
        # Terminal & Window operations
        "$mainMod, Return, exec, $terminal"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, Q, killactive,"
        "$mainMod, M, exit,"
        "$mainMod, F, fullscreen, 0"
        "$mainMod SHIFT, V, togglefloating,"
        "$mainMod, P, pseudo,"
        "$mainMod, J, togglesplit,"

        # Noctalia Shell IPC Controls
        "$mainMod, Space, exec, noctalia msg panel-toggle launcher"
        "$mainMod, V, exec, noctalia msg panel-toggle clipboard"
        "$mainMod, S, exec, noctalia msg panel-toggle control-center"
        "$mainMod, comma, exec, noctalia msg settings-toggle"
        "ALT, Tab, exec, noctalia msg window-switcher"

        # Screenshots
        "$mainMod SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"

        # Focus movement
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # Workspace switching (1-9)
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"

        # Move active window to workspace (1-9)
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"

        # Workspace scroll
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
      ];

      bindm = [
        # Move/resize windows with mouse
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      bindl = [
        # Audio & Media binds via Noctalia IPC
        ", XF86AudioRaiseVolume, exec, noctalia msg volume-up"
        ", XF86AudioLowerVolume, exec, noctalia msg volume-down"
        ", XF86AudioMute, exec, noctalia msg volume-mute"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"

        # Brightness binds via Noctalia IPC
        ", XF86MonBrightnessUp, exec, noctalia msg brightness-up"
        ", XF86MonBrightnessDown, exec, noctalia msg brightness-down"
      ];

      # Surface rules for Noctalia Desktop Shell
      layerrule = [
        "blur, noctalia"
        "ignorezero, noctalia"
        "blur, gtk-layer-shell"
      ];
    };
  };
}
