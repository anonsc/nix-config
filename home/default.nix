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
}
