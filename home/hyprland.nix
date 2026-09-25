{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib.generators) mkLuaInline;
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    # Hyprland >= 0.55 uses a Lua config. Home Manager renders `settings` to
    # `hyprland.lua` as follows:
    #   { _var = ... }     -> `local <name> = ...` (Lua local variable)
    #   { _args = [ .. ] } -> multi-argument call, e.g. hl.bind(mod, action, flags)
    #   mkLuaInline "..."  -> raw Lua expression
    #   anything else      -> hl.<name>({ ... }) call (lists: one call per item)
    # Do NOT use hyprlang "$var" strings here; they produce invalid Lua.
    settings = {
      # Lua locals, usable inside mkLuaInline expressions below
      mainMod = { _var = "SUPER"; };
      terminal = { _var = "ptyxis"; };
      fileManager = { _var = "nautilus"; };

      # Autostart Noctalia desktop shell & export session environment
      on = [
        {
          _args = [
            "hyprland.start"
            (mkLuaInline ''
              function()
                hl.exec_cmd("noctalia")
                hl.exec_cmd("systemctl --user import-environment PATH WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
                hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
              end
            '')
          ];
        }
      ];

      monitor = {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = 1;
      };

      config = {
        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          col = {
            active_border = {
              colors = [
                "rgba(89b4faee)"
                "rgba(cba6f7ee)"
              ];
              angle = 45;
            };
            inactive_border = "rgba(585b70aa)";
          };
          layout = "dwindle";
        };

        decoration = {
          rounding = 12;
          blur = {
            enabled = true;
            size = 4;
            passes = 2;
            vibrancy = 0.1696;
          };
          shadow = {
            enabled = true;
            range = 8;
            render_power = 2;
            # rgba(1a1a1aee) in old hyprlang == 0xEE1A1A1A (0xAARRGGBB) in lua
            color = mkLuaInline "0xEE1A1A1A";
          };
        };

        animations.enabled = true;

        dwindle = {
          # NOTE: dwindle.pseudotile was removed in Hyprland 0.55's Lua config.
          # Pseudo is now per-window only: SUPER+P bind (hl.dsp.window.pseudo())
          # or a windowrule effect `pseudo = true`.
          preserve_split = true;
        };

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
        };
      };

      # bezier "myBezier, 0.05, 0.9, 0.1, 1.05" in the old format
      curve = [
        {
          _args = [
            "myBezier"
            {
              type = "bezier";
              points = [
                [ 0.05 0.9 ]
                [ 0.1 1.05 ]
              ];
            }
          ];
        }
      ];

      animation = [
        # every hl.animation requires bezier = "..." or spring = "..."
        { leaf = "windows"; enabled = true; speed = 5; bezier = "myBezier"; }
        { leaf = "windowsOut"; enabled = true; speed = 5; bezier = "myBezier"; style = "popin 80%"; }
        { leaf = "border"; enabled = true; speed = 8; bezier = "default"; }
        { leaf = "fade"; enabled = true; speed = 5; bezier = "default"; }
        { leaf = "workspaces"; enabled = true; speed = 4; bezier = "default"; }
      ];

      # Layer rules for Noctalia desktop shell
      layer_rule = [
        {
          match.namespace = "noctalia";
          blur = true;
        }
        {
          # old hyprlang "ignorezero" == ignore fully transparent pixels
          match.namespace = "noctalia";
          ignore_alpha = 0;
        }
        {
          match.namespace = "gtk-layer-shell";
          blur = true;
        }
      ];

      bind = [
        # Terminal & window operations
        {
          _args = [
            (mkLuaInline ''mainMod .. " + Return"'')
            (mkLuaInline "hl.dsp.exec_cmd(terminal)")
          ];
        }
        {
          _args = [
            (mkLuaInline ''mainMod .. " + E"'')
            (mkLuaInline "hl.dsp.exec_cmd(fileManager)")
          ];
        }
        {
          _args = [
            (mkLuaInline ''mainMod .. " + Q"'')
            (mkLuaInline "hl.dsp.window.close()")
          ];
        }
        {
          _args = [
            (mkLuaInline ''mainMod .. " + M"'')
            (mkLuaInline ''hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'exit'")'')
          ];
        }
        {
          _args = [
            (mkLuaInline ''mainMod .. " + F"'')
            (mkLuaInline ''hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })'')
          ];
        }
        {
          _args = [
            (mkLuaInline ''mainMod .. " + SHIFT + V"'')
            (mkLuaInline ''hl.dsp.window.float({ action = "toggle" })'')
          ];
        }
        {
          _args = [
            (mkLuaInline ''mainMod .. " + P"'')
            (mkLuaInline "hl.dsp.window.pseudo()")
          ];
        }
        {
          _args = [
            (mkLuaInline ''mainMod .. " + J"'')
            (mkLuaInline ''hl.dsp.layout("togglesplit")'')
          ];
        }

        # Noctalia Shell IPC controls
        {
          _args = [
            (mkLuaInline ''mainMod .. " + Space"'')
            (mkLuaInline ''hl.dsp.exec_cmd("noctalia msg panel-toggle launcher")'')
          ];
        }
        {
          _args = [
            (mkLuaInline ''mainMod .. " + V"'')
            (mkLuaInline ''hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard")'')
          ];
        }
        {
          _args = [
            (mkLuaInline ''mainMod .. " + S"'')
            (mkLuaInline ''hl.dsp.exec_cmd("noctalia msg panel-toggle control-center")'')
          ];
        }
        {
          _args = [
            (mkLuaInline ''mainMod .. " + comma"'')
            (mkLuaInline ''hl.dsp.exec_cmd("noctalia msg settings-toggle")'')
          ];
        }
        {
          _args = [
            "ALT + Tab"
            (mkLuaInline ''hl.dsp.exec_cmd("noctalia msg window-switcher")'')
          ];
        }

        # Screenshots
        {
          _args = [
            (mkLuaInline ''mainMod .. " + SHIFT + S"'')
            (mkLuaInline ''hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy")'')
          ];
        }

        # Focus movement
        {
          _args = [
            (mkLuaInline ''mainMod .. " + left"'')
            (mkLuaInline ''hl.dsp.focus({ direction = "left" })'')
          ];
        }
        {
          _args = [
            (mkLuaInline ''mainMod .. " + right"'')
            (mkLuaInline ''hl.dsp.focus({ direction = "right" })'')
          ];
        }
        {
          _args = [
            (mkLuaInline ''mainMod .. " + up"'')
            (mkLuaInline ''hl.dsp.focus({ direction = "up" })'')
          ];
        }
        {
          _args = [
            (mkLuaInline ''mainMod .. " + down"'')
            (mkLuaInline ''hl.dsp.focus({ direction = "down" })'')
          ];
        }

        # Workspace scroll
        {
          _args = [
            (mkLuaInline ''mainMod .. " + mouse_down"'')
            (mkLuaInline ''hl.dsp.focus({ workspace = "e+1" })'')
          ];
        }
        {
          _args = [
            (mkLuaInline ''mainMod .. " + mouse_up"'')
            (mkLuaInline ''hl.dsp.focus({ workspace = "e-1" })'')
          ];
        }

        # Move/resize windows with mouse
        {
          _args = [
            (mkLuaInline ''mainMod .. " + mouse:272"'')
            (mkLuaInline "hl.dsp.window.drag()")
            { mouse = true; }
          ];
        }
        {
          _args = [
            (mkLuaInline ''mainMod .. " + mouse:273"'')
            (mkLuaInline "hl.dsp.window.resize()")
            { mouse = true; }
          ];
        }

        # Audio & media binds via Noctalia IPC (locked = work while locked)
        {
          _args = [
            "XF86AudioRaiseVolume"
            (mkLuaInline ''hl.dsp.exec_cmd("noctalia msg volume-up")'')
            { locked = true; repeating = true; }
          ];
        }
        {
          _args = [
            "XF86AudioLowerVolume"
            (mkLuaInline ''hl.dsp.exec_cmd("noctalia msg volume-down")'')
            { locked = true; repeating = true; }
          ];
        }
        {
          _args = [
            "XF86AudioMute"
            (mkLuaInline ''hl.dsp.exec_cmd("noctalia msg volume-mute")'')
            { locked = true; }
          ];
        }
        {
          _args = [
            "XF86AudioMicMute"
            (mkLuaInline ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")'')
            { locked = true; }
          ];
        }
        {
          _args = [
            "XF86AudioPlay"
            (mkLuaInline ''hl.dsp.exec_cmd("playerctl play-pause")'')
            { locked = true; }
          ];
        }
        {
          _args = [
            "XF86AudioNext"
            (mkLuaInline ''hl.dsp.exec_cmd("playerctl next")'')
            { locked = true; }
          ];
        }
        {
          _args = [
            "XF86AudioPrev"
            (mkLuaInline ''hl.dsp.exec_cmd("playerctl previous")'')
            { locked = true; }
          ];
        }

        # Brightness binds via Noctalia IPC
        {
          _args = [
            "XF86MonBrightnessUp"
            (mkLuaInline ''hl.dsp.exec_cmd("noctalia msg brightness-up")'')
            { locked = true; repeating = true; }
          ];
        }
        {
          _args = [
            "XF86MonBrightnessDown"
            (mkLuaInline ''hl.dsp.exec_cmd("noctalia msg brightness-down")'')
            { locked = true; repeating = true; }
          ];
        }
      ];
    };

    # Workspace switching & moving (1-9), generated with a Lua loop.
    # `mainMod` is the local defined via `_var` above.
    extraConfig = ''
      for i = 1, 9 do
        hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
        hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i, follow = true }))
      end
    '';
  };
}
