with builtins;
let
  ipam = {
    shammas = [ "198.74.56.101/32" "2600:3c03:e002:2510::/64" ];
    nycr6 = [ "23.239.10.184/32" "2600:3c03:e002:2511::/64" ];
    nextcloud = [ "192.168.55.12/32" "2600:3c03:e002:2512::/64" ];
    tanya = [ "23.239.10.144/32" "2600:3c03:e002:2513::/64" ];
    avalon = [ "192.168.55.14/32" "2600:3c03:e002:2514::/64" ];
  };

in
host:
{ pkgs, lib, config, ... }:
{
  system.stateVersion = "23.11";

  boot.swraid.enable = false;
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


  networking = {
    useHostResolvConf = false;
    useNetworkd = true;
    domain = "fu.io";
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];

    firewall = {
      allowedTCPPorts =
        [ 80 443 ];
    };
  };

  systemd.network.networks.eth0 = {
    name = "eth0";
    address = ipam.${host};
    routes = [
      {
        routeConfig = {
          Gateway = "169.254.0.1";
          GatewayOnLink = "yes";
          Scope = "global";
        };
      }
      {
        routeConfig = {
          Gateway = "FE80::1";
          GatewayOnLink = "yes";
          Scope = "global";
        };
      }
    ];
  };


  environment.systemPackages = with pkgs; [ htop vim git tcpdump restic ];
  security.acme = { acceptTerms = true; defaults.email = "acme@shamm.as"; };
  services.dbus.implementation = "broker";
  services.postfix = {
    enable = true;
    relayHost = "192.168.55.1";
    relayPort = 25;
    rootAlias = "root@shamm.as";
    domain = "fu.io";
  };
}
