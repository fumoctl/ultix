{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../common.nix
    ./hardware-configuration.nix
    ./disko.nix
  ];

  networking.hostName = "fumonix-laptop";

  programs.captive-browser = {
    enable = true;
    interface = "wlp98s0";
  };

  boot.loader.limine = {
    secureBoot.enable = lib.mkDefault false;
  };

  boot.kernelPackages = lib.mkDefault (
    if pkgs ? linuxPackages_cachyos-lto-znver4 then
      pkgs.linuxPackages_cachyos-lto-znver4.extend (final: prev: {
        tuxedo-drivers = prev.tuxedo-drivers.override { pahole = pkgs.pahole; };
      })
    else
      pkgs.linuxPackages_latest
  );

  # NVIDIA PRIME hybrid graphics
  services.xserver.videoDrivers = ["modesetting" "nvidia"];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    package = lib.mkDefault (
      if pkgs ? nvidia_cachyos-lto then
        pkgs.nvidia_cachyos-lto
      else
        config.boot.kernelPackages.nvidiaPackages.stable
    );
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    nvidiaSettings = true;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      amdgpuBusId = "PCI:66:0:0";
      nvidiaBusId = "PCI:64:0:0";
    };
  };

  hardware.tuxedo-drivers.enable = true;

  hardware.tuxedo-rs = {
    enable = true;
    tailor-gui.enable = true;
  };
}
