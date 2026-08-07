{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    bottom
    difftastic
    dust
    fd
    imv
    jq
    just
    marksman
    nixd
    nixfmt
    ripgrep
    taplo
    vscode-langservers-extracted
    wl-clipboard
  ];

  xdg.configFile."imv/config".source = ./config/imv/config;

  programs.git.enable = true;

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    settings = {
      editor = "hx";
      git_protocol = "ssh";
    };
  };

  programs.direnv = {
    enable = true;
    enableNushellIntegration = true;
    nix-direnv.enable = true;
  };
}
