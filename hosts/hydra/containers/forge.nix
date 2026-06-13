{ pkgs, ... }:
{
  containers.forge = {
    autoStart = true;
    hostBridge = "virtbr0";
    privateNetwork = true;
    extraFlags = [ "-U" ];
    enableTun = true;

    config =
      { config, ... }:
      {
        nixpkgs.pkgs = pkgs;
        imports = [ (import ./common.nix "forge") ];

        networking.firewall.allowedUDPPorts = [ 443 ];
        networking.firewall.allowedTCPPorts = [
          2222
          3000
          3080
        ];
        networking.nftables.tables.forgenat = {
          family = "inet";
          content = ''
            chain prerouting {
              type nat hook prerouting priority 0; policy accept;
              tcp dport 22 redirect to 2222
              tcp dport 80 redirect to 3080
              tcp dport 443 redirect to 3000
            }
          '';
        };

        services.forgejo = {
          enable = true;
          package = pkgs.forgejo;
          database.type = "postgres";
          settings = {

            server = {
              DOMAIN = "forge.scalable.io";
              ROOT_URL = "https://forge.scalable.io";

              PROTOCOL = "https";
              REDIRECT_OTHER_PORT = true;
              PORT_TO_REDIRECT = 3080;
              ENABLE_ACME = true;
              ACME_ACCEPTTOS = true;
              ACME_EMAIL = "acme@shamm.as";
              ACME_URL = "https://acme-v02.api.letsencrypt.org/directory";

              START_SSH_SERVER = true;
              SSH_LISTEN_PORT = 2222;
              BUILTIN_SSH_SERVER_USER = "git";
              SSH_SERVER_MACS = "hmac-sha2-256-etm@openssh.com";
              SSH_SERVER_KEY_EXCHANGES = "curve25519-sha256";

            };
            cron.ENABLED = true;
            service = {
              DISABLE_REGISTRATION = true;
              REGISTER_EMAIL_CONFIRM = true;
            };
            oauth2_client = {
              ENABLE_AUTO_REGISTRATION = true;
            };
            federation.enabled = true;
            cache.ADAPTER = "redis";
            session.PROVIDER = "redis";
            queue.TYPE = "redis";
            mailer = {
              ENABLED = true;
              FROM = "forgejo@scalable.io";
              PROTOCOL = "smtp";
              SMTP_ADDR = "192.168.55.1";
              SMTP_PORT = "25";

            };
          };
        };

        services.postgresql = {
          package = pkgs.postgresql_17;
        };

        services.redis.servers."" = {
          enable = true;
        };
      };

  };
}
