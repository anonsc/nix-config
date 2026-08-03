#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

smoke_dir="$(mktemp -d /tmp/nix-config-rust-smoke.XXXXXXXX)"
cleanup() {
  case "$smoke_dir" in
    /tmp/nix-config-rust-smoke.*) rm -rf -- "$smoke_dir" ;;
  esac
}
trap cleanup EXIT

mkdir -p "$smoke_dir/cargo-home" "$smoke_dir/project"
ln -s "$repo_root/home/config/cargo/config.toml" "$smoke_dir/cargo-home/config.toml"

cd "$smoke_dir/project"
cargo init --quiet --bin --name rust-smoke .

# Prove that the personal Cargo config supplies these optimizations without
# relying on the environment-variable implementation that it replaced.
unset RUSTC_WRAPPER
unset CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER
unset CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_RUSTFLAGS

CARGO_HOME="$smoke_dir/cargo-home" cargo build --verbose 2>&1 | tee "$smoke_dir/build.log"

grep -F "sccache" "$smoke_dir/build.log" >/dev/null
grep -F "linker=clang" "$smoke_dir/build.log" >/dev/null
grep -F "link-arg=-fuse-ld=mold" "$smoke_dir/build.log" >/dev/null

cargo --version
rustc --version
rust-analyzer --version
sccache --show-stats
echo "Personal Cargo config selected sccache, clang, and mold."
