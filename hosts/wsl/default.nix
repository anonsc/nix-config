{ pkgs, ... }:
let
  # The upstream Nerd Font archive also contains the 3:5 HackGen35 variant.
  # Expose only the regular 1:2 HackGen Console NF family to Linux fontconfig.
  hackgenNf12 = pkgs.hackgen-nf-font.overrideAttrs {
    pname = "hackgen-nf-1-2-font";
    installPhase = ''
      runHook preInstall

      install -Dm644 HackGenConsoleNF-*.ttf -t $out/share/fonts/hackgen-nf

      runHook postInstall
    '';
  };
in
{
  imports = [
    ../../modules/docker.nix
    ../../modules/nix-settings.nix
  ];

  wsl = {
    enable = true;
    defaultUser = "dnc";
    interop = {
      # Re-register the Windows PE handler if systemd-binfmt replaces WSL's
      # initial binfmt_misc state. Without it, .exe files fail with ENOEXEC.
      register = true;
      includePath = true;
    };
  };

  networking.hostName = "nixos-wsl";
  time.timeZone = "Asia/Tokyo";

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
  fonts.packages = [ hackgenNf12 ];
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "26.05";
}
