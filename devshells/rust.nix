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

  RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
  CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER = "${pkgs.clang}/bin/clang";
  CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_RUSTFLAGS = "-C link-arg=-fuse-ld=${pkgs.mold}/bin/mold";
}
