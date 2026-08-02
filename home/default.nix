{
  imports = [
    ./cli.nix
    ./helix.nix
    ./jj.nix
    ./nushell.nix
    ./zellij.nix
    ../modules/services/sccache.nix
  ];

  home = {
    username = "dnc";
    homeDirectory = "/home/dnc";
    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;

  # On the first NixOS switch, dnc's lingering user manager can start before
  # Home Manager has linked its units. Let WantedBy start them on the next
  # user-manager start instead of making the whole system switch fail.
  systemd.user.startServices = "suggest";
}
