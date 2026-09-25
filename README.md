# ultix

> **Ultix**: A modern, modular, host-separated NixOS 26.05 configuration featuring **Hyprland**, **Noctalia v5** desktop shell, and Btrfs-backed **Impermanence** (erase-your-darlings).

---

## 🌟 Highlights

- **NixOS 26.05 (Yarara) & Home Manager**: Built on the current stable NixOS release with unstable overlays for cutting-edge packages.
- **Modular Host-Separated Architecture**: Clean decoupled separation across hosts (`hosts/desktop`, `hosts/laptop`), system modules (`modules/nixos/`), user environment modules (`modules/home/`), and user declarations (`users/fumoctl/`).
- **Hyprland Wayland Compositor**: Hardware accelerated with AMD Mesa/RADV (desktop) and NVIDIA PRIME offload (laptop), PipeWire low-latency audio, XDG portals, and smooth animations.
- **Noctalia v5 Desktop Shell**: Native Wayland shell integrating status bar, application launcher, control center, lock screen, and window switcher, wired directly to Hyprland keybinds via Noctalia IPC. Pre-configured with the official binary cache (`noctalia.cachix.org`).
- **Btrfs Impermanence**: Ephemeral root filesystem (`@`) with automated `systemd-initrd` rollback to a pristine `@blank` snapshot on boot, automatic safety archiving of previous roots into `/@old_roots/@_<timestamp>` with a 30-day retention policy, and declarative system/user persistence under `/persist`.

---

## 📁 Repository Architecture

```text
.
├── flake.nix                                # Flake entry point (inputs, substituters, hosts)
├── flake.lock                               # Pinned dependency revisions
├── README.md                                # Project documentation
│
├── hosts/                                   # The 2 Host Folders + Shared Base
│   ├── common.nix                           # Shared NixOS (Impermanence, Hyprland, Noctalia, user)
│   ├── desktop/
│   │   ├── default.nix                      # 'fumonix-desktop' entry point (AMDGPU, Zen 4)
│   │   ├── hardware-configuration.nix       # AMD Ryzen 7600X + Radeon RX 7900 hardware scan
│   │   └── disko.nix                        # Desktop NVMe layout with @persist
│   └── laptop/
│       ├── default.nix                      # 'fumonix-laptop' entry point (NVIDIA PRIME)
│       ├── hardware-configuration.nix       # Laptop hardware scan
│       └── disko.nix                        # Laptop NVMe layout with @persist
│
└── home/                                    # Modular Home Manager
    ├── default.nix                          # Home entry point importing modular components
    ├── hyprland.nix                         # Hyprland session, rules, and Noctalia IPC binds
    ├── noctalia.nix                         # Noctalia v5 bar, widgets, and themes
    ├── impermanence.nix                     # Home Manager impermanence bindings
    └── shell.nix                            # Zsh, Git, terminal (Ptyxis), and CLI utilities
```

---

## 🖥️ Hosts

| Hostname | Role | CPU / GPU | Kernel | Storage |
| :--- | :--- | :--- | :--- | :--- |
| **`fumonix-desktop`** | Primary Workstation | AMD Ryzen 5 7600X / AMD Radeon RX 7900 | CachyOS LTO Znver4 | LUKS NVMe (Btrfs with `@persist`) |
| **`fumonix-laptop`** | Mobile Device | AMD CPU / NVIDIA RTX (PRIME Offload) | CachyOS / Linux | LUKS NVMe (Btrfs with `@persist`) |

---

## 🧊 Impermanence & Btrfs Rollback

### How it Works
1. On every boot, while still inside the early `initrd` stage before `sysroot.mount`:
   - The root Btrfs filesystem is mounted to a temporary location (`/btrfs_tmp`).
   - The existing root subvolume (`/@`) is safely rotated into `/@old_roots/@_<timestamp>` (so you never lose uncommitted files).
   - Old archived roots older than 30 days are automatically pruned.
   - The pristine, empty snapshot `/@blank` is snapshotted into `/@`.
   - The filesystem is unmounted, and systemd boots into a completely clean root.
2. The `@persist` subvolume is mounted to `/persist` with `neededForBoot = true`.
3. `environment.persistence."/persist"` binds persistent machine state:
   - Machine ID (`/etc/machine-id`)
   - SSH Host keys (`/etc/ssh/ssh_host_*`)
   - NetworkManager connection profiles (`/etc/NetworkManager/system-connections`)
   - Bluetooth pairings (`/var/lib/bluetooth`)
   - System state (`/var/lib/nixos`, `/var/lib/systemd/coredump`)
4. `home.persistence."/persist"` automatically binds persistent user state:
   - Dotfiles and state (`~/.local/state/noctalia`, `~/.config/noctalia`, `~/.ssh`, `~/.gnupg`)
   - Personal directories (`Downloads`, `Documents`, `Pictures`, `Videos`, `Music`, `Projects`)

### Initial Setup: Creating `@blank` Snapshot
On a freshly partitioned disk, create the pristine `@blank` snapshot once before enabling rollback:
```bash
# Mount the root btrfs pool
sudo mount -o subvol=/ /dev/mapper/crypted /mnt

# Take a read-only blank snapshot of the empty root subvolume
sudo btrfs subvolume snapshot -r /mnt/@ /mnt/@blank

# Unmount
sudo umount /mnt
```
*(Note: If `@blank` does not exist yet, the `btrfs-rollback` service will automatically create an empty `@` subvolume as a safety fallback so boot never fails).*

### 🛡️ Are Unpersisted Files Lost on Boot? (No!)
**No! In this configuration, nothing is immediately destroyed.**

Every time the machine boots:
1. The active root subvolume (`/@`) is safely renamed and moved to:
   ```text
   /@old_roots/@_YYYY-MM-DD_HH:MM:SS
   ```
2. The pristine snapshot `/@blank` is snapshotted into `/@`.
3. Old root archives are preserved for **30 days** before being pruned.

If you created or modified files in `/etc`, `/var`, or other root locations outside `/persist`, they are preserved inside `/@old_roots`.

### 📂 How to Recover Files from a Previous Root
If you realize you left un-persisted files in an older root, recover them at any time:

```bash
# 1. Mount the top-level Btrfs pool
sudo mkdir -p /mnt/btrfs-root
sudo mount -o subvol=/ /dev/mapper/crypted /mnt/btrfs-root

# 2. View all previous system roots
ls -la /mnt/btrfs-root/@old_roots/

# 3. Copy any needed files back into your home or persistent storage
cp -r /mnt/btrfs-root/@old_roots/@_<timestamp>/path/to/file ~/Projects/

# 4. Clean up mount
sudo umount /mnt/btrfs-root
```

### 🔄 Rolling Back NixOS Generations in the Bootloader
If you select an older NixOS generation from the Limine bootloader:
- **Your Personal Files (`/home` and `/persist`)**: All personal files, documents, games, browser data, and dotfiles **remain completely untouched**. NixOS generational rollbacks only swap system packages and configurations; they never touch user data.
- **Your System Software**: Reverts to the exact software state, packages, and kernel of that selected generation.
- **Root Snapshot Safety**: Because every boot rotates the root into `/@old_roots`, ephemeral state is safely preserved even across generation switches.

---

## 🔮 Noctalia v5 Shell & Hyprland Integration

Noctalia is integrated directly into the Hyprland session via Noctalia's native IPC socket.

### Keybindings

| Keybinding | Action | Command |
| :--- | :--- | :--- |
| <kbd>Super</kbd> + <kbd>Space</kbd> | Toggle App Launcher | `noctalia msg panel-toggle launcher` |
| <kbd>Super</kbd> + <kbd>V</kbd> | Toggle Clipboard History | `noctalia msg panel-toggle clipboard` |
| <kbd>Super</kbd> + <kbd>E</kbd> | Open File Manager (Nautilus) | `nautilus` |
| <kbd>Super</kbd> + <kbd>S</kbd> | Toggle Control Center | `noctalia msg panel-toggle control-center` |
| <kbd>Super</kbd> + <kbd>,</kbd> | Toggle Noctalia Settings | `noctalia msg settings-toggle` |
| <kbd>Alt</kbd> + <kbd>Tab</kbd> | Window Switcher | `noctalia msg window-switcher` |
| <kbd>Super</kbd> + <kbd>Return</kbd> | Open Terminal (Ptyxis) | `ptyxis` |
| <kbd>Super</kbd> + <kbd>Q</kbd> | Close Active Window | `hyprctl dispatch killactive` |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd> | Fullscreen Screenshot (focused monitor) | `noctalia msg screenshot-fullscreen` |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Ctrl</kbd> + <kbd>S</kbd> | Region Screenshot | `noctalia msg screenshot-region` |
| <kbd>Volume Up / Down / Mute</kbd> | Noctalia Volume OSD | `noctalia msg volume-up / down / mute` |
| <kbd>Brightness Up / Down</kbd> | Noctalia Brightness OSD | `noctalia msg brightness-up / down` |

---

## 🚀 Building & Deploying

### Verify & Check Flake
```bash
# Verify flake syntax and outputs
nix flake check

# Dry-run build desktop configuration
nix build .#nixosConfigurations.fumonix-desktop.config.system.build.toplevel --dry-run

# Dry-run build laptop configuration
nix build .#nixosConfigurations.fumonix-laptop.config.system.build.toplevel --dry-run
```

### Apply Configuration to Live System
```bash
# Rebuild and switch (desktop)
sudo nixos-rebuild switch --flake .#fumonix-desktop

# Rebuild and switch (laptop)
sudo nixos-rebuild switch --flake .#fumonix-laptop

# Test configuration before committing
sudo nixos-rebuild test --flake .#fumonix-desktop
```
