{ config, pkgs, ... }:
let
  cacheDir = config.home.sessionVariables.SCCACHE_DIR;
in
{
  systemd.user.services.sccache = {
    Unit = {
      Description = "Shared sccache compilation cache";
      Documentation = [ "https://github.com/mozilla/sccache" ];
    };

    Service = {
      Type = "simple";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${cacheDir}";
      # SCCACHE_START_SERVER starts the server, while SCCACHE_NO_DAEMON keeps
      # it in the foreground for systemd. Passing --start-server as well is a
      # conflicting second start request on sccache 0.17 and causes a restart
      # loop.
      ExecStart = "${pkgs.sccache}/bin/sccache";
      Restart = "on-failure";
      RestartSec = 2;
      Environment = [
        "SCCACHE_START_SERVER=1"
        "SCCACHE_NO_DAEMON=1"
        "SCCACHE_IDLE_TIMEOUT=0"
        "SCCACHE_DIR=${cacheDir}"
        "SCCACHE_CACHE_SIZE=20G"
      ];
    };

    Install.WantedBy = [ "default.target" ];
  };
}
