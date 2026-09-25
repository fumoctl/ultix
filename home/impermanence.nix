{
  config,
  lib,
  pkgs,
  ...
}:

{
  # In modern impermanence, specify the base persistent path (e.g. "/persist")
  # and the user's home directory path is appended automatically.
  home.persistence."/persist" = {
    directories = [
      "Downloads"
      "Documents"
      "Pictures"
      "Videos"
      "Music"
      "Projects"
      "Games"
      ".vscode"
      ".vscode-shared"
      ".copilot"
      ".duckdb"
      ".steam"
      ".ssh"
      ".gnupg"
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
      ".local/state/noctalia"
      ".local/state/wireplumber"
      ".config/noctalia"
      ".config/Code"
      ".config/Antigravity"
      ".config/equibop"
      ".config/BraveSoftware"
      ".config/MangoHud"
      ".config/dconf"
      ".config/gthumb"
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
}
