{ config, ... }:
{

  networking.wireguard.interfaces = {
    wg0 = {
      privateKeyFile = config.age.secrets."local-wg-key".path;
      listenPort = 51821;
      ips = [ "192.168.59.1/32" ];
      peers = [
        {
          allowedIPs = [ "10.73.105.241/32" ];
          endpoint = "127.0.0.1:51820";
          publicKey = "wozD1mT5ODoD0if630mgiVOp8GHQmEXqRFvBo9NP9gM=";
        }
      ];

    };
  };
}
