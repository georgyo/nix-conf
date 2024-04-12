{
  pkgs,
  lib,
  config,
  ...
}:
{

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    settings = {
      max_connections = "200";
      shared_buffers = "4GB";
      effective_cache_size = "12GB";
      maintenance_work_mem = "1GB";
      checkpoint_completion_target = "0.9";
      wal_buffers = "16MB";
      default_statistics_target = "100";
      random_page_cost = "1.1";
      effective_io_concurrency = "200";
      work_mem = "5242kB";
      huge_pages = "off";
      min_wal_size = "1GB";
      max_wal_size = "4GB";
      max_worker_processes = "8";
      max_parallel_workers_per_gather = "4";
      max_parallel_workers = "8";
      max_parallel_maintenance_workers = "4";
    };
    initdbArgs = [ "--data-checksums" ];
    enableJIT = true;
  };

  containers.temp-pg.config = {
    # Just to clear compile warnings
    boot.swraid.enable = false;

    system.stateVersion = "23.11";
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16;

      ## set a custom new dataDir
      # dataDir = "/some/data/dir";
    };
  };

  environment.systemPackages =
    let
      newpg = config.containers.temp-pg.config.services.postgresql;
    in
    [
      (pkgs.writeScriptBin "upgrade-pg-cluster" ''
        set -x
        export OLDDATA="${config.services.postgresql.dataDir}"
        export NEWDATA="${newpg.dataDir}"
        export OLDBIN="${config.services.postgresql.package}/bin"
        export NEWBIN="${newpg.package}/bin"
          
        install -d -m 0700 -o postgres -g postgres "$NEWDATA"
        cd "$NEWDATA"
        sudo -u postgres $NEWBIN/initdb --data-checksums -D "$NEWDATA"
          
        systemctl stop postgresql    # old one
          
        sudo -u postgres $NEWBIN/pg_upgrade \
          --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
          --old-bindir $OLDBIN --new-bindir $NEWBIN \
          "$@"
      '')
    ];
}
