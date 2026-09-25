{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    ptyxis
    fastfetch
    btop
    eza
    bat
    fzf
    ripgrep
    fd
    bibata-cursors
    kdePackages.breeze-icons
  ];

  # SSH client configuration with non-symlink permission safety
  home.file.".ssh/config_source" = {
    text = ''
      Host github.com
          HostName github.com
          User git
          IdentityFile ~/.ssh/fumossh.key

      Host *
          IdentityFile ~/.ssh/id_ed25519
          IdentitiesOnly yes
    '';
    onChange = ''
      cp ~/.ssh/config_source ~/.ssh/config
      chmod 600 ~/.ssh/config
    '';
  };

  # Git with commit signing
  programs.git = {
    enable = true;
    signing = {
      key = "35FAC098F119E8FA";
      signByDefault = true;
    };
    settings = {
      user = {
        name = "JuanU";
        email = "juanu@fumoctl.com";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "dpoggi";
      plugins = [
        "git"
        "sudo"
      ];
    };
  };

  # Visual Studio Code
  programs.vscode = {
    enable = true;
    package = pkgs.unstable.vscode;
    mutableExtensionsDir = true;
  };

  # Brave Browser with privacy and utility extensions
  programs.brave = {
    enable = true;
    extensions = [
      { id = "ghmbeldphafepmbegfdlkpapadhbakde"; } # Proton Pass (Password manager)
      { id = "ldpochfccmkkmhdbclfhpagapcfdljkj"; } # Decentraleyes (Local CDN emulation)
      { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; } # Privacy Badger (Heuristic tracker blocker)
      { id = "ghbmnnjooekpmoecnnnilnnbdlolhkhi"; } # Google Docs Offline
      { id = "gbkeegbaiigmenfmjfclcdgdpimamgkj"; } # Google Docs MS Office
      { id = "donbcfbmhbcapadipfkeojnmajbakjdc"; } # Ruffle - Flash Emulator
    ];
  };

  # Flatpak Integration & Management
  services.flatpak = {
    enable = true;
    packages = [
      "com.github.tchx84.Flatseal"
      "com.obsproject.Studio"
      "com.usebottles.bottles"
      "com.vysp3r.ProtonPlus"
      "com.github.Matoking.protontricks"
      "com.ranfdev.DistroShelf"
    ];
    update.auto = {
      enable = true;
      onCalendar = "daily";
    };
    uninstallUnmanaged = false;
  };

  home.activation = {
    configureFlatpakLanguages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.flatpak}/bin/flatpak config --user --set languages "en;ja"
    '';

    fixobsqt = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.flatpak}/bin/flatpak override --user --unset-env=QT_PLUGIN_PATH --unset-env=LD_LIBRARY_PATH --unset-env=QT_QPA_PLATFORM_PLUGIN_PATH com.obsproject.Studio
    '';

    overrideBottlesFsHome = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.flatpak}/bin/flatpak override --user --filesystem=home com.usebottles.bottles
    '';

    flatpakThemeOverrides = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.flatpak}/bin/flatpak override --user \
        --filesystem=/nix/store:ro \
        --filesystem=xdg-data/themes:ro \
        --filesystem=xdg-data/icons:ro \
        --filesystem=xdg-config/gtk-3.0:ro \
        --filesystem=xdg-config/gtk-4.0:ro
    '';
  };

  # Terminal Emulator (Ptyxis) settings & desktop launcher
  dconf.settings = {
    "org/gnome/Ptyxis" = {
      restore-session = false;
    };
  };

  xdg.desktopEntries."org.gnome.Ptyxis" = {
    name = "Ptyxis";
    genericName = "Terminal";
    comment = "Container-oriented terminal emulator";
    exec = "ptyxis --new-window %U";
    icon = "org.gnome.Ptyxis";
    terminal = false;
    categories = [
      "System"
      "TerminalEmulator"
    ];
    startupNotify = true;
  };

  # XDG MIME associations
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "x-scheme-handler/mailto" = "thunderbird.desktop";

      "text/plain" = "code.desktop";
      "text/markdown" = "code.desktop";
      "text/x-markdown" = "code.desktop";

      "application/json" = "code.desktop";
      "application/x-yaml" = "code.desktop";
      "text/yaml" = "code.desktop";
      "text/x-yaml" = "code.desktop";
      "application/toml" = "code.desktop";
      "text/x-toml" = "code.desktop";
      "application/xml" = "code.desktop";
      "text/xml" = "code.desktop";
      "text/x-ini" = "code.desktop";
      "text/x-properties" = "code.desktop";

      "application/x-shellscript" = "code.desktop";
      "text/x-shellscript" = "code.desktop";
      "application/x-bash" = "code.desktop";
      "text/x-python" = "code.desktop";
      "application/x-python-code" = "code.desktop";
      "text/x-lua" = "code.desktop";

      "text/x-c" = "code.desktop";
      "text/x-csrc" = "code.desktop";
      "text/x-chdr" = "code.desktop";
      "text/x-c++" = "code.desktop";
      "text/x-c++src" = "code.desktop";
      "text/x-c++hdr" = "code.desktop";
      "text/x-rust" = "code.desktop";
      "text/rust" = "code.desktop";
      "text/x-go" = "code.desktop";
      "text/javascript" = "code.desktop";
      "application/javascript" = "code.desktop";
      "text/typescript" = "code.desktop";
      "application/typescript" = "code.desktop";
      "text/css" = "code.desktop";
      "text/x-scss" = "code.desktop";
      "text/x-sql" = "code.desktop";

      "text/x-diff" = "code.desktop";
      "text/x-patch" = "code.desktop";
      "text/x-dockerfile" = "code.desktop";
      "text/x-makefile" = "code.desktop";
      "text/x-cmake" = "code.desktop";

      "inode/directory" = "org.gnome.Nautilus.desktop";

      # Photos & Images (gThumb)
      "image/jpeg" = "org.gnome.gThumb.desktop";
      "image/png" = "org.gnome.gThumb.desktop";
      "image/gif" = "org.gnome.gThumb.desktop";
      "image/webp" = "org.gnome.gThumb.desktop";
      "image/svg+xml" = "org.gnome.gThumb.desktop";
      "image/bmp" = "org.gnome.gThumb.desktop";
      "image/tiff" = "org.gnome.gThumb.desktop";
      "image/avif" = "org.gnome.gThumb.desktop";
      "image/heic" = "org.gnome.gThumb.desktop";
      "image/x-icon" = "org.gnome.gThumb.desktop";

      # Music & Audio
      "audio/mpeg" = "org.gnome.Lollypop.desktop";
      "audio/flac" = "org.gnome.Lollypop.desktop";
      "audio/x-vorbis+ogg" = "org.gnome.Lollypop.desktop";
      "audio/ogg" = "org.gnome.Lollypop.desktop";
      "audio/mp4" = "org.gnome.Lollypop.desktop";
      "audio/aac" = "org.gnome.Lollypop.desktop";
      "audio/x-wav" = "org.gnome.Lollypop.desktop";

      # Compressed Archives
      "application/zip" = "org.gnome.FileRoller.desktop";
      "application/x-tar" = "org.gnome.FileRoller.desktop";
      "application/x-compressed-tar" = "org.gnome.FileRoller.desktop";
      "application/x-bzip-compressed-tar" = "org.gnome.FileRoller.desktop";
      "application/x-xz-compressed-tar" = "org.gnome.FileRoller.desktop";
      "application/x-zstd-compressed-tar" = "org.gnome.FileRoller.desktop";
      "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
      "application/vnd.rar" = "org.gnome.FileRoller.desktop";
      "application/x-rar" = "org.gnome.FileRoller.desktop";
      "application/gzip" = "org.gnome.FileRoller.desktop";
      "application/x-bzip2" = "org.gnome.FileRoller.desktop";
      "application/x-xz" = "org.gnome.FileRoller.desktop";

      # Documents & PDF
      "application/pdf" = "org.gnome.Evince.desktop";

      # Video Players
      "video/mp4" = "mpv.desktop";
      "video/mkv" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/quicktime" = "mpv.desktop";
      "video/x-msvideo" = "mpv.desktop";
    };
  };
}
