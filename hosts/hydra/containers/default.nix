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
  };

  imports = [
    ./nextcloud.nix
    ./nycr6.nix
    ./shammas
    ./tanya.nix
    ./avalon
    ./forge.nix
    ./derp.nix
    # ./surrealdb
    ./pocketid
    # ./authelia
    ./niks3
  ];
}
