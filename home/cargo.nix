{ pkgs, ... }:

{
  home.packages = with pkgs; [
    clang
    mold
    sccache
  ];
  home.file.".cargo/config.toml".source = ./config/cargo/config.toml;
}
