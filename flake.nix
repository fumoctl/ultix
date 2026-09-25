{
  description = "Ultix: Modular host-separated NixOS 26.05 configuration with Hyprland, Noctalia, and Impermanence";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    github-copilot-nix = {
      url = "github:fumoctl/GithubCopilot-Nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://noctalia.cachix.org"
      "https://nyx-cache.chaotic.cx"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
    ];
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      disko,
      chaotic,
      nix-flatpak,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations = {
        fumonix-desktop = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            nix-flatpak.nixosModules.nix-flatpak
            chaotic.nixosModules.nyx-cache
            chaotic.nixosModules.nyx-overlay
            chaotic.nixosModules.nyx-registry
            ./hosts/desktop/default.nix
          ];
        };

        fumonix-laptop = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            nix-flatpak.nixosModules.nix-flatpak
            chaotic.nixosModules.nyx-cache
            chaotic.nixosModules.nyx-overlay
            chaotic.nixosModules.nyx-registry
            ./hosts/laptop/default.nix
          ];
        };
      };
    };
}
