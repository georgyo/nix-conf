{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.frr = {
    bgp.enable = true;
    bgp.config = ''
      router bgp 65001
      no bgp ebgp-requires-policy
      coalesce-time 1000
      bgp bestpath as-path multipath-relax
      neighbor RS peer-group
      neighbor RS remote-as external
      neighbor RS ebgp-multihop 10
      neighbor RS capability extended-nexthop
      neighbor 2600:3c0f:6:34::1 peer-group RS
      neighbor 2600:3c0f:6:34::2 peer-group RS
      neighbor 2600:3c0f:6:34::3 peer-group RS
      neighbor 2600:3c0f:6:34::4 peer-group RS

      address-family ipv4 unicast
        #hydra
        network 172.104.14.163/32 route-map primary

        network 172.104.15.252/32 route-map primary

        # wiki.nycresistor.com
        network 23.239.10.184/32 route-map primary

        # tor.shamm.as -> Tanya
        network 23.239.10.144/32 route-map primary

        # ifconfig.io -> shammas
        network 23.239.9.39/32 route-map primary

        # shammas
        network 198.74.56.101/32 route-map primary

        #network 66.228.36.99/32 route-map primary
        redistribute static
      exit-address-family

      address-family ipv6 unicast
        network 2600:3c03:e002:2500::/56 route-map primary
        network 2600:3c03:e002:7400::/56 route-map primary
        redistribute static
      exit-address-family

      route-map primary permit 10
        set community 65000:1
      route-map secondary permit 10
        set community 65000:2
    '';
    zebra.enable = true;
    mgmt.enable = true;
    mgmt.config = ''
      ipv6 nht resolve-via-default
    '';

  };
}
