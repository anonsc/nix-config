let
  identity = {
    name = "anonsc";
    email = "102777199+anonsc@users.noreply.github.com";
  };
in
{
  imports = [
    ./cargo.nix
    ./cli.nix
    ./environment.nix
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
  programs.git.settings = {
    user = identity;

    # Repositories and bootstrap scripts often publish HTTPS clone URLs. Each
    # WSL environment carries its own default GitHub SSH key, so transparently
    # route those URLs through that environment's key instead of prompting for
    # an HTTPS username and token.
    url."git@github.com:".insteadOf = "https://github.com/";
  };
  programs.jujutsu.settings.user = identity;

  # On the first NixOS switch, dnc's lingering user manager can start before
  # Home Manager has linked its units. Let WantedBy start them on the next
  # user-manager start instead of making the whole system switch fail.
  systemd.user.startServices = "suggest";
}
