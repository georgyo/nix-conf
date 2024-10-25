{
  config,
  lib,
  pkgs,
  ...
}:

let
  nycr-element-web = pkgs.element-web.override {
    conf = {
      default_server_config = {
        "m.homeserver" = {
          base_url = "https://nycr.chat";
          server_name = "nycr.chat";
        };
        "m.identity_server" = {
          base_url = "https://vector.im";
        };
      };
      defaultCountryCode = "US";
      showLabsSettings = true;
      "enable_presence_by_hs_url" = {
        "https://matrix.org" = true;
        "https://matrix-client.matrix.org" = false;
      };
      jitsi.preferredDomain = "meet.nycr.chat";
    };
  };

  fqdn = "nycr.chat";
  baseUrl = "https://nycr.chat:443";
  serverConfig = {
    "m.server" = "${fqdn}:443";
  };
  clientConfig = {
    "m.homeserver" = {
      "base_url" = baseUrl;
    };
    "org.matrix.msc3575.proxy" = {
      "url" = "https://syncv3.nycr.chat";
    };
  };
  mkWellKnown = data: ''
    add_header Content-Type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';
in
{

  imports = [
    ./coturn.nix
    ./heisenbridge.nix
  ];

  sops.secrets = {
    "matrix/appservice-discord.env" = {
      sopsFile = ./secrets/environment.yaml;
      key = "appservice-discord";
      restartUnits = [ "matrix-appservice-discord.service" ];
    };
    "matrix/discord-registration.yaml" = {
      format = "binary";
      sopsFile = ./secrets/discord-registration.yamlb;
      owner = config.users.users.matrix-synapse.name;
      group = config.users.users.matrix-synapse.group;
      restartUnits = [ "matrix-synapse.service" ];
    };
    "matrix/heisenbridge-registration.yaml" = {
      format = "binary";
      sopsFile = ./secrets/heisenbridge-registration.yamlb;
      owner = config.users.users.matrix-synapse.name;
      group = config.users.users.matrix-synapse.group;
      restartUnits = [ "matrix-synapse.service" ];
    };
    "matrix/extra-config.yaml" = {
      format = "binary";
      sopsFile = ./secrets/extra-config.yamlb;
      owner = config.users.users.matrix-synapse.name;
      group = config.users.users.matrix-synapse.group;
      restartUnits = [ "matrix-synapse.service" ];
    };
  };

  services.matrix-appservice-discord = {
    enable = true;
    port = 9006;
    # package = /nix/store/r79qklg78z62kpgqpda6wx6gj4cainw6-matrix-appservice-discord;
    environmentFile = config.sops.secrets."matrix/appservice-discord.env".path;
    settings = {
      bridge = {
        domain = "nycr.chat";
        homeserverUrl = "https://nycr.chat";
        port = 9006;
        enableSelfServiceBridging = true;
        adminMxid = "@georgyo:nycr.chat";
      };
      auth = {
        usePrivilegedIntents = true;
      };
      database = {
        filename = "/var/lib/matrix-appservice-discord/discord.db";
      };
    };
  };

  services.matrix-synapse = {
    enable = true;
    withJemalloc = true;
    log.root.level = "WARNING";
    settings = {
      public_baseurl = "https://nycr.chat/";
      server_name = "nycr.chat";
      app_service_config_files = [
        config.sops.secrets."matrix/discord-registration.yaml".path
        config.sops.secrets."matrix/heisenbridge-registration.yaml".path
      ];
      presence.enabled = true;
      enable_registration = false;
      enable_registration_captcha = true;
      recaptcha_public_key = "6LcrI1gpAAAAAKm0ySV8exH23RPWnTytZJNaM-f_";
      turn_uris = [
        "turn:${config.services.coturn.realm}:5349?transport=udp"
        "turn:${config.services.coturn.realm}:5349?transport=tcp"
      ];
      suppress_key_server_warning = true;
      turn_user_lifetime = "1h";
      listeners = [
        {
          bind_addresses = [ "" ];
          port = 8447;
          resources = [
            {
              compress = true;
              names = [ "client" ];
            }
            {
              compress = false;
              names = [ "federation" ];
            }
          ];
          tls = false;
          type = "http";
          x_forwarded = true;
        }
      ];
      email = {
        enable_notifs = true;
        smtp_host = "localhost";
        smtp_port = 25; # SSL: 465, STARTTLS: 587
        require_transport_security = false;
        notif_from = "Your Friendly %(app)s homeserver <noreply@nycr.chat>";
        notif_for_new_users = true;
        # https://github.com/matrix-org/synapse/tree/master/synapse/res/templates
        notif_template_html = "notif_mail.html";
        notif_template_text = "notif_mail.txt";
        expiry_template_html = "notice_expiry.html";
        expiry_template_text = "notice_expiry.txt";
      };
    };
    plugins = with config.services.matrix-synapse.package.plugins; [
      matrix-synapse-ldap3
      matrix-synapse-pam
      #matrix-synapse-s3-storage-provider
    ];
    extraConfigFiles = [ config.sops.secrets."matrix/extra-config.yaml".path ];
  };

  services.nginx = {
    virtualHosts."nycr.chat" = {
      listen = [
        {
          addr = "[::]";
          port = 80;
        }
        {
          addr = "0.0.0.0";
          port = 80;
        }
        {
          addr = "[::]";
          port = 443;
          ssl = true;
        }
        {
          addr = "[::]";
          port = 8448;
          ssl = true;
        }
        {
          addr = "0.0.0.0";
          port = 443;
          ssl = true;
        }
        {
          addr = "0.0.0.0";
          port = 8448;
          ssl = true;
        }
      ];
      forceSSL = true;
      enableACME = true;
      quic = true;
      #locations."= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;
      locations."= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;
      locations."/".proxyPass = "http://127.0.0.1:8447";
    };
    virtualHosts."www.nycr.chat" = {
      forceSSL = true;
      enableACME = true;
      quic = true;
      #locations."= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;
      locations."= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;
      locations."/".proxyPass = "http://127.0.0.1:8447";
    };
    virtualHosts."syncv3.nycr.chat" = {
      forceSSL = true;
      enableACME = true;
      quic = true;
      locations."/".proxyPass = "http://127.0.0.1:8009";
    };
    virtualHosts."matrix.nycr.chat" = {
      forceSSL = true;
      enableACME = true;
      quic = true;
      locations."/".proxyPass = "http://127.0.0.1:8447";
    };
  };
}
