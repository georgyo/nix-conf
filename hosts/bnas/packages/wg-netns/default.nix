{
  config,
  pkgs,
  lib,
  ...
}:
let
  wg-netns = pkgs.callPackage ./package.nix { };
  script = ''
    ${wg-netns}/bin/wg-netns up seed
    until  ${pkgs.iproute2}/bin/ip netns exec seed ${pkgs.coreutils}/bin/true; do
      echo will retry
      ${pkgs.coreutils}/bin/sleep 1
    done
    ${pkgs.iproute2}/bin/ip netns exec seed ${seed-firewall}
  '';
  seed-firewall = pkgs.writeScript "seed.nft" ''
    #!${pkgs.nftables}/bin/nft -f
    flush ruleset

    define private_network = {192.168.59.0/24, 100.64.0.0/10}

    table inet filter {
            chain INPUT {
                    type filter hook input priority 0; policy drop;
                    iifname "lo" accept
                    ct state invalid counter drop comment "Drop invalid connections"
                    ct state established,related accept comment "Accept traffic originated from us"
                    iifname "seed" ip saddr $private_network counter accept
                    iifname "seed" counter drop
                    counter drop
            }
            chain FORWARD {
                    type filter hook forward priority 0; policy drop;
                    ct state invalid counter drop comment "Drop invalid connections"
                    ct state established,related counter accept comment "Accept traffic we are responding to"
                    counter drop
            }
            chain OUTPUT {
                    type filter hook output priority 0; policy drop;
                    oifname "lo" accept
                    ct state invalid counter drop comment "Drop invalid connections"
                    ct state established,related accept comment "Accept traffic we are responding to"
                    oifname "seed" ip daddr $private_network meta l4proto icmp counter accept
                    oifname "seed" ip daddr $private_network counter reject with icmpx type admin-prohibited
                    oifname "seed" accept
                    counter reject with icmpx type admin-prohibited
            }
    }
  '';

in

{
  options = { };
  config = {
    environment.systemPackages = [ wg-netns ];
    systemd.services."wg-netns@seed" = {
      wants = [
        "network-online.target"
        "nss-lookup.target"
      ];
      after = [
        "network-online.target"
        "nss-lookup.target"
      ];
      wantedBy = [ "multi-user.target" ];
      path = [ wg-netns ];
      environment = {
        WG_ENDPOINT_RESOLUTION_RETRIES = "infinity";
        WG_VERBOSE = "1";
        WG_PROFILE_DIR = "/run/agenix/seedns";
      };
      inherit script;
      serviceConfig = {
        #        ExecStart = "i";
        # ExecStartPost = "${pkgs.coreutils}/bin/sleep 5 && ${pkgs.iproute2}/bin/ip netns exec %i ${seed-firewall}";
        ExecStop = "${wg-netns}/bin/wg-netns down %i";
        Type = "oneshot";
        RemainAfterExit = true;

        WorkingDirectory = "%E/wireguard";
        ConfigurationDirectory = "wireguard";
        ConfigurationDirectoryMode = "0700";

        CapabilityBoundingSet = "CAP_NET_ADMIN CAP_SYS_ADMIN";
        LimitNOFILE = "4096";
        LimitNPROC = "512";
        LockPersonality = "true";
        MemoryDenyWriteExecute = "true";
        NoNewPrivileges = "true";
        ProtectClock = "true";
        ProtectHostname = "true";
        RemoveIPC = "true";
        RestrictAddressFamilies = "AF_INET AF_INET6 AF_NETLINK";
        RestrictNamespaces = "mnt net";
        RestrictRealtime = "true";
        RestrictSUIDSGID = "true";
        SystemCallArchitectures = "native";
      };

    };
  };
}
