# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  lib,
  ...
}:

with pkgs;
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./time.nix
    ./environment.nix
    ./postgresql.nix
    ./matrix
    ./syncthing.nix
    ./containers
    ./mastodon
    ./tailscale.nix
    ./secrets
    ./lemmy.nix
    ./bird.nix
    ./geoip.nix
  ];

  services.murmur.enable = true;
  documentation.info.enable = false;

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.kernel.sysctl = {
    "net.ipv4.tcp_rmem" = "8192 262144 536870912";
    "net.ipv4.tcp_wmem" = "4096 16384 536870912";
    "net.ipv4.tcp_adv_win_scale" = "-2";
    "net.ipv4.tcp_collapse_max_bytes" = "6291456";
    "net.ipv4.tcp_notsent_lowat" = "131072";
    "net.ipv6.conf.all.forwarding" = 1;
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_ecn" = 1;
  };
  services.resolved.enable = true;
  systemd.network.wait-online.anyInterface = true;
  systemd.settings.Manager = {
    DefaultLimitNOFILE = "8192:524288";
  };
  security.pam.loginLimits = [
    {
      domain = "*";
      item = "nofile";
      type = "soft";
      value = "8192";
    }
  ];
  networking = {
    hostName = "hydra"; # Define your hostname.
    domain = "shamm.as";
    usePredictableInterfaceNames = false;

    useNetworkd = true;

    interfaces.eth0 = {
      ipv4 = {
        addresses = [
          {
            address = "172.104.14.163";
            prefixLength = 24;
          }
        ];
        routes = [
          {
            address = "0.0.0.0";
            prefixLength = 0;
            via = "172.104.14.1";
          }
        ];
      };
      ipv6 = {
        addresses = [
          {
            address = "2600:3c03::f03c:91ff:fed8:373c";
            prefixLength = 128;
          }
        ];
        routes = [
          {
            address = "::";
            prefixLength = 0;
            via = "fe80::1";
          }
        ];
      };
    };

    nat.enable = true;
    nat.externalInterface = "eth0";
    nat.internalInterfaces = [ "tailscale0" ];

    nftables.enable = true;
    nftables.tables = {
      nat = {
        content = ''
          chain post {
            type nat hook postrouting priority srcnat - 10;
            iifname { "virtbr0" } oifname "eth0" ip saddr 192.168.55.0/24 counter masquerade comment "from internal interfaces"
          }
        '';
        family = "ip";
      };
    };

    firewall = {
      enable = true;
      allowedTCPPorts = [
        80
        443
        8000
        8080
        8448
        3478
        3479
        5349
        5350
        9898
        9969
        64738
      ];
      allowedUDPPorts = [
        443
        51820
        3478
        3479
        5349
        5350
        9969
        64738
      ];
      allowedUDPPortRanges = [
        {
          from = 49000;
          to = 50000;
        }
      ];
      allowedTCPPortRanges = [
        {
          from = 49000;
          to = 50000;
        }
      ];
      allowPing = true;
      extraForwardRules = ''
        iifname eth0 ip daddr 172.104.15.252 accept
        iifname eth0 ip daddr 23.239.10.144 accept
        iifname eth0 ip daddr 23.239.10.184 accept
        iifname eth0 ip daddr 66.228.36.99 accept
      '';
      logRefusedConnections = false;
      trustedInterfaces = [
        "virtbr0"
        "tailscale0"
      ];
    };

    # wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  };

  nix = {
    settings = {
      sandbox = true;
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nixbuild.net/georgyo-1:spPZa4Zj/AsToKwV8Owne5QephxJHcZU9wDpdFlMjhw="
        "shammas-1:vYHw6rxALD2kGfWSDiEZqsaUmcGGLMDd9/J5D2piF/Q="
      ];
      auto-optimise-store = true;
    };
  };

  services.dbus.implementation = "broker";

  security.pam.sshAgentAuth = {
    enable = true;
    authorizedKeysFiles = [ "/etc/ssh/authorized_keys.d/%u" ];
  };
  services.openssh = {
    enable = true;
    authorizedKeysFiles = [ "/etc/ssh/authorized_keys.d/%u" ];
    moduliFile = pkgs.runCommand "moduli" { } ''
      ${pkgs.gawk}/bin/awk '$5 >= 3071' ${config.programs.ssh.package}/etc/ssh/moduli > $out
    '';
    settings = {
      PermitRootLogin = "no";
      Ciphers = [
        # "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
        # "aes128-gcm@openssh.com"
        # "aes256-ctr"
        # "aes192-ctr"
        # "aes128-ctr"
      ];
      KexAlgorithms = [
        "sntrup761x25519-sha512@openssh.com"
        # "curve25519-sha256"
        # "curve25519-sha256@libssh.org"
        # "diffie-hellman-group-exchange-sha256"
        "diffie-hellman-group16-sha512"
        "diffie-hellman-group18-sha512"
      ];
      Macs = [
        "hmac-sha2-512-etm@openssh.com"
        # "hmac-sha2-256-etm@openssh.com"
        # "umac-128-etm@openssh.com"
      ];
    };
  };

  services.postfix = {
    enable = true;
    settings.main = {
      myhostname = "hydra.shamm.as";
      mydomain = "shamm.as";
      relayhost = [
        "email-smtp.us-east-1.amazonaws.com:587"
      ];
      mynetworks = [
        "192.168.55.0/24"
        "172.104.15.252/32"
        "198.74.56.101/32"
        "23.239.10.144/32"
        "23.239.10.184/32"
        "23.239.9.39/32"
        "66.228.36.99/32"
        "127.0.0.1/8"
        "[::1]/128"
      ];
      smtp_sasl_auth_enable = "yes";
      smtp_sasl_security_options = "noanonymous";
      smtp_sasl_password_maps = "hash:/etc/postfix_oob/sasl_passwd";
      smtp_use_tls = "yes";
      smtp_tls_security_level = "encrypt";
      smtp_tls_note_starttls_offer = "yes";
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.root.shell = pkgs.zsh;
  users.extraUsers.shammas = {
    isNormalUser = true;
    createHome = true;
    uid = 1000;
    shell = pkgs.zsh;
    hashedPassword = "$y$jFT$vdqpPuiuE4qydpZCmz0aW1$ZWUDLC1zZ.P/LH4du3GDyj6tPr1GRdr18EE7nilthH7";
    extraGroups = [
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHIR85OQWCKZz8AofJcLO48UnvVlXZaKGlelYOx6WITP shammas@glap"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKrAxJtkMUjVhFJ2o5UPXbQLn8Q92c3g4xuCjCBtNmnz shammas@bigtower"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKhItTwa8QPZ+HuLEzAtYzD5U+HmE53QAsahdjHGx8rm 1password"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGF99yGzL9/m2X8W1ea6gjifSY4s2dinLhUijuYbgfaX georg@DESKTOP-AIUJF2H"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOnJ+uG3t57MAdhYyvZhYULS5XYkqfAxWh//iBGblVaz shammas@gtmlap"
    ];
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  # system.stateVersion = "18.03"; # Did you read the comment?
  system.stateVersion = "22.11";

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    commonHttpConfig =
      let
        realIpsFromList = lib.strings.concatMapStringsSep "\n" (x: "set_real_ip_from  ${x};");
      in
      ''
        ${realIpsFromList pkgs.cloudflare_ips_v4}
        ${realIpsFromList pkgs.cloudflare_ips_v6}
        real_ip_header CF-Connecting-IP;

        log_format  main  '$remote_addr $host $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" ';

        access_log  /var/log/nginx/access.log  main;
      '';

    virtualHosts."default.nycr.chat" = {
      default = true;
      forceSSL = true;
      enableACME = true;
      quic = true;
      root = "/var/lib/acme/acme-challenges";
    };
    virtualHosts."meet.nycr.chat" = {
      enableACME = true;
      forceSSL = true;
      quic = true;
    };
  };

  services.logrotate.settings.nginx.frequency = "daily";
  services.logrotate.settings.header = {
    compresscmd = "${pkgs.zstd}/bin/zstd";
    compressext = ".zst";
    compressoptions = "-T0 --long";
    uncompresscmd = "${pkgs.zstd}/bin/unzstd";
  };

  security.acme = {
    defaults.email = "acme@shamm.as";
    acceptTerms = true;
  };

}
