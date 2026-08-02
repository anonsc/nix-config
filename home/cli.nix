{ pkgs, ... }:
{
  home.packages = with pkgs; [
    android-tools
    difftastic
    fd
    just
    ripgrep
    sccache
  ];

  programs.git.enable = true;

  programs.direnv = {
    enable = true;
    enableNushellIntegration = true;
    nix-direnv.enable = true;
  };
}
