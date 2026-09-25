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
    kdePackages.qt6ct
  ];

  # GTK theming: use adw-gtk3-dark (matches theme.mode = "dark") so Noctalia's
  # generated CSS applies on top, and give the shell an icon theme (Noctalia
  # resolves app icons through GTK's icon-theme support).
  gtk = {
    enable = true;
    theme.name = "adw-gtk3-dark";
    iconTheme.name = "breeze";
  };

  qt = {
    enable = true;
    platformTheme.name = "kde"; # Uses native KDE theming/KColorScheme
  };

  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "kde";
  };

  # Cursor theme: Bibata Modern Ice. HM's pointerCursor module installs the
  # package, links it into ~/.icons & $XDG_DATA_HOME/icons and exports
  # XCURSOR_THEME/XCURSOR_SIZE + HYPRCURSOR_THEME/HYPRCURSOR_SIZE session vars.
  # gtk.enable also fills gtk.cursorTheme for the settings.ini/dconf config
  # above (so GTK apps match). Hyprland has no native hyprcursor theme here,
  # but hyprcursor falls back to the XCursor theme from $share/icons.
  home.pointerCursor = {
    enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
    gtk.enable = true;
    hyprcursor.enable = true;
  };

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      theme = {
        templates.builtin_ids = [
          "gtk3"
          "gtk4"
          "kcolorscheme"
        ];
      };
      wallpaper = {
          enabled = true;
          path = "../dotfiles/wallpaper.png";
          default.path = "../dotfiles/wallpaper.png";
      };
  };
  };

  home.file = {
  # Target path (relative to home directory)
  ".config/noctalia/noctconf.toml" = {
    source = ../dotfiles/noctconf.toml;  # Path to file
    recursive = true;       # If source is a directory
  };
  };
}
