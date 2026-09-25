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

  # Runtime deps for Noctalia's theming hooks:
  # - adw-gtk3: the GTK theme the template's apply.sh looks up and syncs
  #   (adw-gtk3 / adw-gtk3-dark depending on light/dark mode)
  # - glib: provides `gsettings`, used by the GTK apply hook to set
  #   org.gnome.desktop.interface gtk-theme / color-scheme
  home.packages = with pkgs; [
    adw-gtk3
    glib
  ];

  # GTK theming: use adw-gtk3-dark (matches theme.mode = "dark") so Noctalia's
  # generated CSS applies on top, and give the shell an icon theme (Noctalia
  # resolves app icons through GTK's icon-theme support).
  gtk = {
    enable = true;
    theme.name = "adw-gtk3-dark";
    iconTheme.name = "breeze";
  };

  # Qt theming: route Qt5/Qt6 apps through qt5ct/qt6ct (HM installs both and
  # exports QT_QPA_PLATFORMTHEME) and select the `noctalia` color scheme that
  # Noctalia's `qt` template writes into ~/.config/qt{5,6}ct/colors/.
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    qt5ctSettings.Appearance = {
      custom_palette = true;
      color_scheme_path = "$HOME/.config/qt5ct/colors/noctalia.conf";
    };
    qt6ctSettings.Appearance = {
      custom_palette = true;
      color_scheme_path = "$HOME/.config/qt6ct/colors/noctalia.conf";
    };
  };

  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    settings = {
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Catppuccin";

        # Built-in theme templates (this list is the allowlist). Enables
        # app theming so the Noctalia palette follows GTK & Qt apps:
        #   gtk3/gtk4 -> ~/.config/gtk-{3,4}.0/noctalia.css + apply.sh hook
        #   that imports it into gtk.css and syncs adw-gtk3(-dark) +
        #   org.gnome.desktop.interface color-scheme on dark/light switches.
        #   qt -> ~/.config/qt{5,6}ct/colors/noctalia.conf palettes
        templates.builtin_ids = [
          "gtk3"
          "gtk4"
          "qt"
        ];
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
