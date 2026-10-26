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

5. **(Optional) Restore SOPS Age master key**:

    If you are setting up your own machine, restore your Age key before installing so private keys decrypt on first boot:

    ```bash
    sudo mkdir -p /mnt/persist/sops
    sudo nano /mnt/persist/sops/fumosops.key   # paste your AGE-SECRET-KEY-1...
    sudo chown -R 1000:1000 /mnt/persist/sops
    sudo chmod 700 /mnt/persist/sops
    sudo chmod 600 /mnt/persist/sops/fumosops.key
    ```

    _Note: If installing without this key, the system still builds and installs completely fine; secrets decryption is skipped automatically._

6. **Install NixOS**:

   ```bash
   sudo swapon /mnt/.swapvol/swapfile
   sudo mkdir -p /mnt/var/tmp/nix-build
   sudo TMPDIR=/mnt/var/tmp/nix-build nixos-install --flake github:fumoctl/ultix#<hostname>
   ```
   (setting tmpdir avoids out of memory errors when building from source)

7. **Reboot**:
   ```bash
   reboot
   ```

