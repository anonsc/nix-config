{ pkgs }:
pkgs.mkShell {
  packages = with pkgs; [
    cargo
    cargo-make
    clang
    clippy
    mold
    pkg-config
    rust-analyzer
    rustc
    rustfmt
    sccache
  ];
}
