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
    # ./kubo.nix
    ./tailscale.nix
    ./secrets
    # ./surrealdb.nix
    ./lemmy.nix
    ./frr.nix
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
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  # boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  services.resolved.enable = true;
  systemd.network.wait-online.anyInterface = true;
  systemd.extraConfig = ''
    DefaultLimitNOFILE=8192:524288
  '';
  security.pam.loginLimits = [
    {
      domain = "*";
      item = "nofile";
      type = "soft";
      value = "8192";
    }
  ];
  #systemd.network = {
  #    enable = true;
  #    networks.eth0 = {
  #      matchConfig = {
  #        Name = "eth0";
  #      };
  #      gateway = [
  #        "172.104.14.1"
  #        "fe80::1"
  #      ];
  #      address = [
  #        "172.104.14.163/24"
  #        "2600:3c03::f03c:91ff:fed8:373c/128"
  #      ];
  #    };
  #};

  networking = {
    hostName = "hydra"; # Define your hostname.
    domain = "shamm.as";
    # hosts = {
    #  "192.168.54.142" = [ "dir1.n.shamm.as" ];
    #  "192.168.54.171" = [ "dir3.n.shamm.as" ];
    #};
    usePredictableInterfaceNames = false;

    useNetworkd = true;

    #defaultGateway = {
    #  address = "172.104.14.1";
    #  interface = "eth0";
    #};
    #defaultGateway6 = {
    #  address = "fe80::1";
    #  interface = "eth0";
    #};
    # nameservers = [ "1.1.1.1" "8.8.8.8" ];
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

    firewall = {
      enable = true;
      allowedTCPPorts = [
        80
        443
        3000
        4001
        4002
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
        4001
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
        iifname eth0 ip daddr 192.168.181.165 accept
        iifname eth0 ip daddr 23.239.10.144 accept
        iifname eth0 ip daddr 23.239.10.184 accept
        iifname eth0 ip daddr 23.239.9.39 accept
        iifname eth0 ip daddr 66.228.36.99 accept
      '';
      extraCommands = ''
        iptables -t nat -A PREROUTING -i virtbr0 -s 192.168.55.0/24 -j MARK --set-xmark 0x1/0xffffffff
        iptables -A FORWARD -o virtbr0 -d 172.104.15.252 -j ACCEPT
        iptables -A FORWARD -o virtbr0 -d 198.74.56.101 -j ACCEPT
        iptables -A FORWARD -o virtbr0 -d 23.239.10.144 -j ACCEPT
        iptables -A FORWARD -o virtbr0 -d 23.239.10.184 -j ACCEPT
        iptables -A FORWARD -o virtbr0 -d 23.239.9.39 -j ACCEPT
        iptables -A FORWARD -o virtbr0 -d 66.228.36.99 -j ACCEPT
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
      extra-sandbox-paths = [ "/bin/sh=${pkgs.busybox}/bin/sh" ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nixbuild.net/georgyo-1:spPZa4Zj/AsToKwV8Owne5QephxJHcZU9wDpdFlMjhw="
        "shammas-1:vYHw6rxALD2kGfWSDiEZqsaUmcGGLMDd9/J5D2piF/Q="
      ];
      auto-optimise-store = true;
    };
    package = nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes ca-derivations
    '';
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
        "chacha20-poly1305@openssh.com"
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
    relayHost = "email-smtp.us-east-1.amazonaws.com";
    relayPort = 587;
    hostname = "hydra.shamm.as";
    domain = "shamm.as";
    networks = [
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
    config = {
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
    ];
  };

  home-manager.users.shammas =
    { ... }:
    {

      home.packages = [ pkgs.emacs ];

      home.stateVersion = "23.11";
    };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  # system.stateVersion = "18.03"; # Did you read the comment?
  system.stateVersion = "22.11";

  services.hydra = {
    enable = false;
    hydraURL = "http://hydra.shamm.as:3000"; # externally visible URL
    notificationSender = "hydra@shamm.as"; # e-mail of hydra service
    # a standalone hydra will require you to unset the buildMachinesFiles list to avoid using a nonexistant /etc/nix/machines
    buildMachinesFiles = [ ];
    # you will probably also want, otherwise *everything* will be built from scratch
    useSubstitutes = true;
  };

  services.prosody.extraConfig = ''
    turncredentials_secret = "${config.services.coturn.static-auth-secret}";
    turncredentials_port = 3478;
    turncredentials_ttl = 3600;
    turncredentials = {
      { type = "stun", host = "${config.services.coturn.realm}" },
      { type = "turn", host = "${config.services.coturn.realm}", port = 5349},
      { type = "turns", host = "${config.services.coturn.realm}", port = 5349, transport = "tcp" }
    }
  '';
  services.prosody.extraPluginPaths = [ "/etc/prosody/plugins" ];
  services.prosody.extraModules = [ "turncredentials" ];

  services.nginx = {
    enable = true;
    package = pkgs.nginxQuic;
    recommendedProxySettings = true;
    commonHttpConfig =
      let
        realIpsFromList = lib.strings.concatMapStringsSep "\n" (x: "set_real_ip_from  ${x};");
        fileToList = x: lib.strings.splitString "\n" (builtins.readFile x);
        cfipv4 = fileToList (
          pkgs.fetchurl {
            url = "https://www.cloudflare.com/ips-v4";
            sha256 = "0ywy9sg7spafi3gm9q5wb59lbiq0swvf0q3iazl0maq1pj1nsb7h";
          }
        );
        cfipv6 = fileToList (
          pkgs.fetchurl {
            url = "https://www.cloudflare.com/ips-v6";
            sha256 = "1ad09hijignj6zlqvdjxv7rjj8567z357zfavv201b9vx3ikk7cy";
          }
        );
      in
      ''
        ${realIpsFromList cfipv4}
        ${realIpsFromList cfipv6}
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
    virtualHosts."hydra.shamm.as" = {
      forceSSL = true;
      enableACME = true;
      quic = true;
      locations."/".proxyPass = "http://127.0.0.1:3000";
    };
    virtualHosts."meet.nycr.chat" = {
      enableACME = true;
      forceSSL = true;
      quic = true;
    };
    virtualHosts."ipfs.scalable.io" = {
      enableACME = true;
      addSSL = true;
      quic = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:4002";
        proxyWebsockets = true;
      };
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

  services.opendkim = {
    enable = true;
    selector = "hydra";
    user = "postfix";
    group = "postfix";
  };
}
