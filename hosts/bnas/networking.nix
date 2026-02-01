{
  config,
  lib,
  pkgs,
  ...
}:

{
  networking = {
    hostName = "bnas";
    domain = "shamm.as";
    hostId = "4e98920d";

    useNetworkd = true;
    nftables.enable = true;

    nat.enable = true;
    nat.externalInterface = "network";
    nat.internalInterfaces = [ "tailscale0" ];
    interfaces.network.useDHCP = true;
    interfaces.enp196s0.useDHCP = false;
    interfaces.eno1.useDHCP = false;
    macvlans.network = {
      mode = "bridge";
      interface = "enp196s0";
    };
    firewall = {
      trustedInterfaces = [
        "virtbr0"
        "tailscale0"
      ];

      allowedTCPPorts = [
        80
        443
        2049
        32400
      ];
      allowedUDPPorts = [
        443
        51820
        51821
      ];

    };
  };

  services.resolved = {
    enable = true;
    settings.Resolve.MulticastDNS = true;
  };

  systemd.services.tailscaled.environment = {
    "TS_DEBUG_FIREWALL_MODE" = "auto";
  };
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    permitCertUid = "traefik";
    serve.enable = true;
    extraSetFlags = [
      "--advertise-exit-node"
      "--accept-routes"
      "--advertise-connector"
    ];
  };

  services.networkd-dispatcher = {
    enable = true;
    rules."50-tailscale" = {
      onState = [ "routable" ];
      script = ''
        ${lib.getExe pkgs.ethtool} -K eth0 rx-udp-gro-forwarding on rx-gro-list off
      '';
    };
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    nssmdns6 = true;
    extraServiceFiles = {
      smb = ''
            <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
            <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
            <service-group>
              <name replace-wildcards="yes">%h</name>
              <service>
        	<type>_smb._tcp</type>
        	<port>445</port>
              </service>
            </service-group>
      '';
    };
    publish.hinfo = true;
    publish.enable = true;
    publish.addresses = true;
    publish.userServices = true;
  };

}
