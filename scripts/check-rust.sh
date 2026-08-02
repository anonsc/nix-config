#!/usr/bin/env bash
set -euo pipefail

expected_wrapper="$(command -v sccache)"
if [[ "${RUSTC_WRAPPER:-}" != "$expected_wrapper" ]]; then
  echo "RUSTC_WRAPPER does not point to the devShell's sccache." >&2
  exit 1
fi

linker="${CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER:-}"
if [[ ! -x "$linker" ]]; then
  echo "The native Rust linker is not executable: $linker" >&2
  exit 1
fi

target_rustflags="${CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_RUSTFLAGS:-}"
mold_path="${target_rustflags##*=}"
if [[ "$target_rustflags" != *"-fuse-ld="* || ! -x "$mold_path" ]]; then
  echo "Native target RUSTFLAGS does not select an executable mold linker: $target_rustflags" >&2
  exit 1
fi

smoke_dir="$(mktemp -d /tmp/nix-config-rust-smoke.XXXXXXXX)"
cleanup() {
  case "$smoke_dir" in
    /tmp/nix-config-rust-smoke.*) rm -rf -- "$smoke_dir" ;;
  esac
}
trap cleanup EXIT

cd "$smoke_dir"
cargo init --quiet --bin --name rust-smoke .
cargo build --verbose

cargo --version
rustc --version
sccache --show-stats
echo "RUSTC_WRAPPER=$RUSTC_WRAPPER"
echo "CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=$linker"
echo "CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_RUSTFLAGS=$target_rustflags"
