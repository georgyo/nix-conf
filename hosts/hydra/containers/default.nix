{ ... }:
{

  systemd.network.netdevs.virtbr0 = {
    netdevConfig = {
      Kind = "bridge";
      Name = "virtbr0";
    };
  };

  systemd.network.networks.virtbr0 = {
    matchConfig.Name = "virtbr0";
    networkConfig = {
      ConfigureWithoutCarrier = "yes";
      Domains = [ "cont.fu.io" ];
    };
    address = [ "192.168.55.1/32" ];
    addresses = [
      {
        Address = "169.254.0.1/16";
        Scope = "link";
      }
      {
        Address = "FE80::1";
        Scope = "link";
      }
    ];
    bridgeConfig.ProxyARP = "yes";
    routes = [
      {
        Destination = "172.104.15.252";
        Scope = "link";
      }
      {
        Destination = "23.239.10.144";
        Scope = "link";
      }
      {
        Destination = "23.239.10.184";
        Scope = "link";
      }
      {
        Destination = "23.239.9.39";
        Scope = "link";
      }
      {
        Destination = "198.74.56.101";
        Scope = "link";
      }
      {
        Destination = "66.228.36.99";
        Scope = "link";
      }

      {
        Destination = "192.168.55.0/24";
        Scope = "link";
      }
      {
        Destination = "2600:3c03:e002:2500::/56";
        Scope = "link";
      }
    ];
  };

  imports = [
    ./nextcloud.nix
    ./nycr6.nix
    ./shammas
    ./tanya.nix
    ./avalon
  ];
}
