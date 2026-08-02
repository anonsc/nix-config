set shell := ["bash", "-euo", "pipefail", "-c"]

# Show the available maintenance commands.
default:
    @just --list

# Format every Nix file.
fmt:
    nix fmt

# Evaluate all flake outputs without building their closures.
check-eval:
    nix flake check --no-build

# Evaluate and build every flake check.
check:
    nix flake check

# Build the NixOS-WSL system without creating a result symlink.
build:
    nix build --no-link .#nixosConfigurations.wsl.config.system.build.toplevel

# Apply the NixOS-WSL system, including the integrated Home Manager profile.
switch:
    sudo nixos-rebuild switch --flake .#wsl

# Apply only dnc's Home Manager profile.
home-switch:
    home-manager switch --flake .#dnc

# Update every pinned flake input in flake.lock.
update:
    nix flake update

# Verify that the Rust development shell supports non-interactive commands.
rust-check:
    nix develop .#rust --command bash ./scripts/check-rust.sh

# Run the safe pre-activation pipeline after reviewing a lock-file update.
preflight: check build
