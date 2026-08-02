{ pkgs, ... }:
{
  systemd.user.services.sccache = {
    Unit = {
      Description = "Shared sccache compilation cache";
      Documentation = [ "https://github.com/mozilla/sccache" ];
    };

    Service = {
      Type = "simple";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /home/dnc/.cache/sccache";
      ExecStart = "${pkgs.sccache}/bin/sccache --start-server";
      Restart = "on-failure";
      RestartSec = 2;
      Environment = [
        "SCCACHE_START_SERVER=1"
        "SCCACHE_NO_DAEMON=1"
        "SCCACHE_IDLE_TIMEOUT=0"
        "SCCACHE_DIR=/home/dnc/.cache/sccache"
        "SCCACHE_CACHE_SIZE=20G"
      ];
    };

    Install.WantedBy = [ "default.target" ];
  };
}
