{
  pkgs,
  lib,
  config,
  ...
}:
{

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
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

  # Nightly compressed dumps of all databases (matrix/mastodon/lemmy/nextcloud/...).
  # Writes to /var/lib/postgresql/backup — make sure that volume has headroom.
  services.postgresqlBackup = {
    enable = true;
    compression = "zstd";
  };
}
