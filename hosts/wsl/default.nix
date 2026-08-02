{ pkgs, ... }:
{
  imports = [
    ../../modules/docker.nix
    ../../modules/nix-settings.nix
  ];

  wsl = {
    enable = true;
    defaultUser = "dnc";
  };

  networking.hostName = "nixos-wsl";

  users.users.dnc = {
    isNormalUser = true;
    description = "Development user";
    extraGroups = [
      "docker"
      "wheel"
    ];
    shell = pkgs.nushell;
    linger = true;
  };

  environment.shells = [ pkgs.nushell ];
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "26.05";
}
