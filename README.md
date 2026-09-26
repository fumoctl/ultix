### Installing an Existing Host

1. **Boot into the NixOS Live USB**.
2. **Verify target disk ID**:
   Ensure the disk ID in ```hosts/desktop/disko.nix``` or ```hosts/laptop/disko.nix``` matches your target drive:
   ```bash
   ls -l /dev/disk/by-id/
   ```
3. **Partition, format, and mount with Disko**:

   ```bash
   sudo nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode disko --flake github:fumoctl/ultix#<hostname>
   ```

   _(Or clone the repo locally and use `--flake .#<hostname>`)_

4. **Initialize persistent user password**:

    Because ```users.mutableUsers = false``` and ```hashedPasswordFile = "/persist/passwords/fumoctl"``` are enforced, you must seed the password hash into ```/persist``` before installing, or the account will be locked on first boot:
    
    ```
    sudo mkdir -p /mnt/persist/passwords
    ```
    ```
    nix-shell -p mkpasswd --run 'mkpasswd -m sha-512' | sudo tee /mnt/persist/passwords/fumoctl
    ```
    ```
    sudo chmod 600 /mnt/persist/passwords/fumoctl
    ```

5. **Install NixOS**:

   ```bash
   sudo swapon /mnt/.swapvol/swapfile
   sudo mkdir -p /mnt/var/tmp/nix-build
   sudo TMPDIR=/mnt/var/tmp/nix-build nixos-install --flake github:fumoctl/ultix#<hostname>
   ```
   (setting tmpdir avoids out of memory errors when building from source)

6. **Reboot**:
   ```bash
   reboot
   ```

