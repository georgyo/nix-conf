{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.traefik-forward-auth;
  settingsFormat = pkgs.formats.yaml { };
  configFile =
    if cfg.configFile != null then
      cfg.configFile
    else
      settingsFormat.generate "config.yaml" cfg.settings;
in
{
  options.services.traefik-forward-auth = {
    enable = lib.mkEnableOption "traefik-forward-auth, a forward authentication service for Traefik";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      description = "The traefik-forward-auth package to use.";
    };

    settings = lib.mkOption {
      type = settingsFormat.type;
      default = { };
      description = ''
        Configuration for traefik-forward-auth in Nix attribute set form.
        Will be converted to YAML. See
        <https://github.com/ItalyPaleAle/traefik-forward-auth/blob/main/docs/03-all-configuration-options.md>
        for available options.
      '';
      example = lib.literalExpression ''
        {
          server.hostname = "auth.example.com";
          server.port = 4181;
          portals = [
            {
              name = "main";
              providers = [
                {
                  type = "oidc";
                  clientID = "my-client-id";
                  tokenIssuer = "https://idp.example.com";
                }
              ];
            }
          ];
        }
      '';
    };

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the configuration file. Mutually exclusive with {option}`settings`.
        Useful when the config contains secrets that shouldn't be in the Nix store.
      '';
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to an environment file loaded by the systemd service.
        Can be used to set secrets like `TFA_CONFIG` or provider credentials.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = (cfg.settings != { }) != (cfg.configFile != null);
        message = "Exactly one of services.traefik-forward-auth.settings or services.traefik-forward-auth.configFile must be set.";
      }
    ];

    systemd.services.traefik-forward-auth = {
      description = "Traefik Forward Auth";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      environment.TFA_CONFIG = toString configFile;

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
        RestartSec = 5;

        DynamicUser = true;
        StateDirectory = "traefik-forward-auth";
        WorkingDirectory = "/var/lib/traefik-forward-auth";

        EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;

        # Hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectClock = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        SystemCallArchitectures = "native";
      };
    };
  };
}
