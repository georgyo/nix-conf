{
  config,
  lib,
  pkgs,
  ...
}:
let
  hostname = "hackertalks.com";
in
{
  sops.secrets = {
    "pict-rs/apikey" = {
      format = "binary";
      sopsFile = ./secrets/pict-rs.apikey;
      restartUnits = [ "lemmy.service" ];
    };
  };

  services.lemmy = {
    enable = true;
    settings = {
      inherit hostname;
      database = {
        pool_size = 5;
      };
      email = {
        smtp_server = "localhost:25";
        smtp_from_address = "noreply@hackertalks.com";
        tls_type = "none";
      };
      pictrs = {
        # Should be deprecated, but external link caching still happens when it is removed
        cache_external_link_previews = false;
        image_mode = "None";

        # These should be getting set automatically from the nixos module, but
        # the attr sets are merging deep enough. The api_key._secret is actually
        # part of the lemmy nixos module and is templated to the correct value
        # right before lemmy starts.
        url = "http://127.0.0.1:8080";
        api_key._secret = "pictrsApiKeyFile";
      };
      worker_count = 5;
      retry_count = 5;
    };
    pictrsApiKeyFile = config.sops.secrets."pict-rs/apikey".path;
    nginx.enable = true;
    caddy.enable = false;
    # database.createLocally = false;
    database.uri = "postgres:///lemmy?host=/run/postgresql&user=lemmy";
  };

  services.nginx.virtualHosts."${hostname}" = {
    forceSSL = true;
    enableACME = true;
    quic = true;
  };

  sops.secrets = {
    "pict-rs/env" = {
      format = "dotenv";
      sopsFile = ./secrets/pict-rs.env;
      restartUnits = [ "pict-rs.service" ];
    };
  };

  systemd.services.lemmy.environment = {
    RUST_LOG = "error";
  };

  systemd.services.pict-rs =
    let
      cfg = config.services.pict-rs;
      config_file = pkgs.writeTextFile {
        name = "pict-rs.toml";
        text = ''
          [server]
          address = '${cfg.address}:${toString cfg.port}'

          [old_db]
          path =  '${cfg.dataDir}'           

          [repo]
          path =  '${cfg.dataDir}'           

          [store]
          type = 'object_storage'
          endpoint = 'https://s3.us-east-2.wasabisys.com'
          bucket_name = 'pict-rs'
          use_path_style = true
          region = 'us-east-2'

          [media.retention]
          variants = "90d"
          proxy = "90d"
        '';
      };
    in
    {
      environment = {
        PICTRS__CONFIG_FILE = config_file;
      };
      serviceConfig.ExecStart = lib.mkForce "${pkgs.pict-rs}/bin/pict-rs --config-file ${config_file} run";
      serviceConfig.EnvironmentFile = [ config.sops.secrets."pict-rs/env".path ];
    };

  services.pict-rs.package = pkgs.pict-rs;
}
