{
  config,
  lib,
  pkgs,
  ...
}:
let
  personalEnvironment = {
    EDITOR = "hx";
    VISUAL = "hx";

    # Personal Rust optimization. Project devShells remain free to replace or
    # unset this without depending on this repository.
    RUSTC_WRAPPER = lib.getExe pkgs.sccache;
    SCCACHE_DIR = "${config.xdg.cacheHome}/sccache";
    SCCACHE_IGNORE_SERVER_IO_ERROR = "1";
  };

  setNushellDefault = name: value: ''
    if "${name}" not-in $env {
      $env.${name} = ${lib.hm.nushell.toNushell { } value}
    }
  '';
in
{
  # Makes the values available to login shells and programs launched from
  # them. These are dnc's preferences, not requirements of project flakes.
  home.sessionVariables = personalEnvironment;

  # Nushell does not source hm-session-vars.sh itself. Set only missing values
  # so a project devShell's environment continues to take precedence.
  programs.nushell.extraEnv = lib.concatStringsSep "\n" (
    lib.mapAttrsToList setNushellDefault personalEnvironment
  );
}
