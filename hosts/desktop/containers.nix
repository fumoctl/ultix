# Host-specific containers for fumonix-desktop.
# Merged with the shared set defined in ../containers.nix.
{ config
, lib
, pkgs
, ...
}:

{
  virtualisation.oci-containers.containers = {
    # Example:
    # some-service = {
    #   image = "docker.io/library/whatever:latest";
    #   autoStart = true;
    #   podman.user = "fumoctl";
    #   ports = [ "8080:8080" ];
    # };
  };
}
