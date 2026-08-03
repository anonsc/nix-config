{ pkgs, ... }:
{
  home.packages = with pkgs; [
    android-tools
    bat
    bottom
    difftastic
    dust
    fd
    jq
    just
    marksman
    nixd
    nixfmt
    ripgrep
    sccache
    taplo
    vscode-langservers-extracted
  ];

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
