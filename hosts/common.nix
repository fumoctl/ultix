{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    inputs.impermanence.nixosModules.impermanence
    inputs.noctalia.nixosModules.default
  ];

  # --- Nix & System Basics ---
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
    auto-optimise-store = lib.mkDefault true;
    substituters = [
      "https://cache.nixos.org"
      "https://noctalia.cachix.org"
      "https://nyx-cache.chaotic.cx"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
    ];
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        system = prev.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    })
    inputs.github-copilot-nix.overlays.default
    inputs.antigravity-nix.overlays.default
  ];

  boot = {
    loader = {
      limine.enable = lib.mkDefault true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };

    kernelModules = [ "ntsync" ];

    kernel.sysctl = {
      "vm.max_map_count" = 2147483642;
      "fs.inotify.max_user_watches" = 524288;
      "fs.inotify.max_user_instances" = 8192;
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
  };

  # System Limits & Systemd Tweaks
  systemd.settings.Manager.DefaultLimitNOFILE = "1048576";
  systemd.user.extraConfig = ''
    DefaultLimitNOFILE=1048576
    DefaultDelegate=yes
  '';
  systemd.package = pkgs.systemd.override { withUserDb = false; };
  services.userdbd.enable = lib.mkForce false;

  security = {
    rtkit.enable = true;
    polkit.enable = true;
    sudo.extraConfig = "Defaults lecture=never";
    pam.loginLimits = [
      {
        domain = "*";
        type = "-";
        item = "nofile";
        value = "1048576";
      }
    ];
  };

  time.timeZone = lib.mkDefault "America/Sao_Paulo";
  services.automatic-timezoned.enable = true;

  i18n = {
    defaultLocale = lib.mkDefault "en_US.UTF-8";
    extraLocales = [ "ja_JP.UTF-8/UTF-8" ];
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "altgr-intl";
  };

  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      nerd-fonts.ubuntu-mono
      nerd-fonts.ubuntu
      nerd-fonts.hack
      nerd-fonts.fira-code
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      ipafont
      kochi-substitute
      noto-fonts-color-emoji
      liberation_ttf
    ];

    fontconfig.defaultFonts = {
      monospace = [
        "JetBrainsMono Nerd Font"
        "Noto Sans Mono CJK JP"
      ];
      sansSerif = [
        "Noto Sans CJK JP"
        "Liberation Sans"
      ];
      serif = [
        "Noto Serif CJK JP"
        "Liberation Serif"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

  # --- Impermanence & Btrfs Rollback ---
  fileSystems."/persist".neededForBoot = true;
  fileSystems."/home".neededForBoot = true;

  boot.initrd.systemd = {
    enable = true;
    services.btrfs-rollback = {
      description = "Rollback BTRFS root subvolume to pristine state";
      wantedBy = [ "initrd.target" ];
      after = [
        "systemd-cryptsetup@crypted.service"
        "initrd-root-device.target"
      ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p /btrfs_tmp
        mount -o subvol=/ /dev/mapper/crypted /btrfs_tmp

        if [ -e /btrfs_tmp/@ ]; then
          mkdir -p /btrfs_tmp/@old_roots
          timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/@)" "+%Y-%m-%d_%H:%M:%S" 2>/dev/null || date "+%Y-%m-%d_%H:%M:%S")
          echo "Archiving current root into /@old_roots/@_$timestamp"
          mv /btrfs_tmp/@ "/btrfs_tmp/@old_roots/@_$timestamp"
        fi

        delete_subvol_recursive() {
          IFS=$'\n'
          for sub in $(btrfs subvolume list -o "$1" 2>/dev/null | cut -f 9- -d ' '); do
            delete_subvol_recursive "/btrfs_tmp/$sub"
          done
          btrfs subvolume delete "$1"
        }

        for old in $(find /btrfs_tmp/@old_roots/ -maxdepth 1 -mtime +30 2>/dev/null); do
          echo "Purging expired snapshot: $old"
          delete_subvol_recursive "$old"
        done

        if [ -e /btrfs_tmp/@blank ]; then
          echo "Restoring pristine root from @blank snapshot"
          btrfs subvolume snapshot /btrfs_tmp/@blank /btrfs_tmp/@
        else
          echo "WARNING: @blank snapshot not found, creating fresh empty @ subvolume"
          btrfs subvolume create /btrfs_tmp/@
        fi

        umount /btrfs_tmp
      '';
    };
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
      "/var/lib/docker"
      "/var/lib/containers"
      "/var/lib/libvirt"
    ];
    files = [
      "/etc/machine-id"
      {
        file = "/etc/ssh/ssh_host_ed25519_key";
        parentDirectory = { mode = "0755"; };
      }
      {
        file = "/etc/ssh/ssh_host_ed25519_key.pub";
        parentDirectory = { mode = "0755"; };
      }
      {
        file = "/etc/ssh/ssh_host_rsa_key";
        parentDirectory = { mode = "0755"; };
      }
      {
        file = "/etc/ssh/ssh_host_rsa_key.pub";
        parentDirectory = { mode = "0755"; };
      }
    ];
  
    users.fumoctl = {
      directories = [
        "Downloads"
        "Documents"
        "Pictures"
        "Videos"
        "Music"
        "Projects"
        "Games"
        "ultix"
        "FumoNix"
        ".vscode"
        ".vscode-shared"
        ".copilot"
        ".gemini"
        ".duckdb"
        ".steam"
        { directory = ".ssh"; mode = "0700"; }
        { directory = ".gnupg"; mode = "0700"; }
        ".var/app"
        ".local/share/direnv"
        ".local/share/steam"
        ".local/share/bottles"
        ".local/share/flatpak"
        ".local/share/containers"
        ".local/share/trash"
        ".local/share/nix"
        ".local/share/keyrings"
        ".local/share/themes"
        ".local/share/icons"
        ".local/share/color-schemes"
        ".local/state/noctalia"
        ".local/state/wireplumber"
        ".config/noctalia"
        ".config/gtk-3.0"
        ".config/gtk-4.0"
        ".config/Code"
        ".config/Antigravity"
        ".config/equibop"
        ".config/BraveSoftware"
        ".config/MangoHud"
        ".config/dconf"
        ".config/lollypop"
        ".config/nautilus"
        ".local/share/lollypop"
        ".local/share/nautilus"
        ".local/share/noctalia"
        ".local/share/gvfs-metadata"
      ];

      files = [
        ".zsh_history"
      ];
    };

  };

  # --- Desktop Subsystem (Hyprland & Noctalia) ---
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  programs.noctalia = {
    enable = true;
    recommendedServices.enable = true;
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  xdg.portal = {
    enable = true;
    wlr.enable = false;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = [ "hyprland" "gtk" ];
      };
      # NOTE: this per-DE section overrides `common` for ALL interfaces when
      # XDG_CURRENT_DESKTOP=Hyprland. The hyprland backend only implements
      # Screenshot/ScreenCast/GlobalShortcuts, so "gtk" must stay in the list
      # or org.freedesktop.portal.Settings disappears from the portal broker
      # and libadwaita apps (Ptyxis etc.) always see light mode.
      hyprland = {
        default = [ "hyprland" "gtk" ];
      };
    };
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    GDK_BACKEND = "wayland,x11,*";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
  };

  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
      theme = "catppuccin-mocha-blue";
      extraPackages = with pkgs; [
        kdePackages.qt5compat
        kdePackages.qtsvg
        kdePackages.qtmultimedia
      ];
    };
    defaultSession = "hyprland";
  };

  # --- Hardware & Input Integrations ---
  networking = {
    nftables.enable = true;
    networkmanager = {
      enable = lib.mkDefault true;
      settings = {
        connection = {
          "wifi.cloned-mac-address" = "stable-temporary";
          "ethernet.cloned-mac-address" = "stable-temporary";
          "ipv6.ip6-privacy" = 2;
        };
        device = {
          "wifi.scan-rand-mac-address" = "yes";
        };
      };
    };
    firewall = {
      enable = true;
      checkReversePath = "loose";
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
    };
  };

  hardware.bluetooth = {
    enable = lib.mkDefault true;
    powerOnBoot = true;
  };
  services.upower.enable = lib.mkDefault true;
  services.power-profiles-daemon.enable = lib.mkDefault true;
  services.lact.enable = true;
  services.libinput = {
    enable = true;
    mouse = {
      accelProfile = "flat";
    };
  };

  # --- Graphics & Gaming Subsystem ---
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = [
      pkgs.unstable.lsfg-vk
    ];
  };

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;
  programs.steam = {
    enable = true;
    extest.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    extraCompatPackages = with pkgs; [
      proton-cachyos
      proton-ge-custom
    ];
  };
  hardware.steam-hardware.enable = true;

  # --- Virtualisation, Containers & Flatpak ---
  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
    };
    podman = {
      enable = true;
      dockerCompat = false;
      dockerSocket.enable = false;
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers = {
      backend = "podman";
      containers = {
        postgres = {
          image = "docker.io/library/postgres:16";
          autoStart = false;
          podman.user = "fumoctl";
          ports = [ "5432:5432" ];
          environment = {
            POSTGRES_PASSWORD = "postgres";
          };
          volumes = [
            "postgres-data:/var/lib/postgresql/data:Z"
          ];
        };
      };
    };
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        vhostUserPackages = with pkgs; [
          virtiofsd
        ];
      };
    };
  };

  programs.virt-manager.enable = true;
  services.spice-vdagentd.enable = true;

  services.flatpak = {
    enable = true;
    uninstallUnmanaged = false;
  };

  # --- File Management, Integration & Thumbnailers ---
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "ptyxis";
  };

  # --- System Utilities & Developer Tooling ---
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-all;
  };

  programs.nix-ld.enable = true;

  documentation.man.cache.enable = true;

  environment.systemPackages = with pkgs; [
    # Development & Editors
    nixd
    nixpkgs-fmt
    nixfmt
    neovim
    git
    meld

    # File Management & Media Openers
    nautilus
    sushi
    file-roller
    kdePackages.gwenview
    lollypop
    evince
    zip
    unzip

    # System & CLI Utilities
    fastfetch
    file
    jq
    pciutils
    ethtool
    sbctl
    _7zz
    unrar
    sshfs
    wget
    curl
    tree
    ripgrep
    fd
    btrfs-progs

    # Container Orchestration & K8s
    docker-compose
    podman-compose
    podman-desktop
    kind
    kubectl
    helm
    k9s
    skopeo
    dive
    shadow
    fuse-overlayfs

    # Wayland & Desktop Integration
    wl-clipboard
    grim
    slurp
    brightnessctl
    playerctl
    wireplumber
    libnotify
    bibata-cursors
    (catppuccin-sddm.override {
      flavor = "mocha";
      accent = "blue";
    })

    # Gaming & Performance
    lact
    mangohud
    goverlay
    unstable.lsfg-vk-ui
    mesa-demos

    # Productivity & Daily Applications
    unstable.equibop
    thunderbird
    unstable.onlyoffice-desktopeditors
    unstable.mullvad-browser
    mpv
    distrobox
    appimage-run
    google-antigravity
    google-antigravity-cli
    github-copilot-desktop
    github-copilot-cli

    # Network Utilities
    dnsmasq
    sshuttle
    waypipe
    iptables
    iproute2

    # Fun & Miscellaneous
    unstable.renpy
    unstable.cowsay
    unstable.lolcat
    unstable.haskellPackages.misfortune
  ];

  # --- User Declaration & Home Manager Integration ---
  programs.zsh.enable = true;

  users.users.fumoctl = {
    isNormalUser = true;
    description = "JuanU";
    group = "fumoctl";
    extraGroups = [
      "wheel"
      "users"
      "networkmanager"
      "video"
      "audio"
      "input"
      "kvm"
      "libvirtd"
      "adm"
      "docker"
      "podman"
    ];
    shell = pkgs.zsh;
    linger = true;
    autoSubUidGidRange = true;
    initialPassword = "changeme";
  };

  users.groups.fumoctl = {};

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.fumoctl = import ../home;
    backupFileExtension = "backup";
  };

  system.stateVersion = "26.05";
}
