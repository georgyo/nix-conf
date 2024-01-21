{ config, pkgs, lib, ... }:
{
  services.kubo = {

    enable = true;
    enableGC = true;
    serviceFdlimit = 65536;
    localDiscovery = false;
    emptyRepo = true;
    settings = {
      Experimental.UrlstoreEnabled = true;
      Experimental.FilestoreEnabled = true;
      # Experimental.AcceleratedDHTClient = true;
      Addresses.Swarm = [
        "/ip4/0.0.0.0/tcp/4002/ws"
        "/ip6/::/tcp/4002/ws"
        "/ip4/0.0.0.0/udp/4001/quic"
        "/ip6/::/udp/4001/quic"
        "/ip4/0.0.0.0/udp/4001/quic-v1"
        "/ip6/0.0.0.0/udp/4001/quic-v1"
        "/ip4/0.0.0.0/udp/4001/quic-v1/webtransport"
        "/ip6/0.0.0.0/udp/4001/quic-v1/webtransport"
      ];
      Peering = {
        Peers = [
          {
            ID = "QmZMxNdpMkewiVZLMRxaNxUeZpDUb34pWjZ1kZvsd16Zic";
            Addrs = [ "/dns4/node0.preload.ipfs.io/tcp/4001" "/dns4/node0.preload.ipfs.io/udp/4001/quic" ];
          }
          {
            ID = "Qmbut9Ywz9YEDrz8ySBSgWyJk41Uvm2QJPhwDJzJyGFsD6";
            Addrs = [ "/dns4/node1.preload.ipfs.io/tcp/4001" "/dns4/node1.preload.ipfs.io/udp/4001/quic" ];
          }
          {
            ID = "QmV7gnbW5VTcJ3oyM2Xk1rdFBJ3kTkvxc87UFGsun29STS";
            Addrs = [ "/dns4/node2.preload.ipfs.io/tcp/4001" "/dns4/node2.preload.ipfs.io/udp/4001/quic" ];
          }
          {
            ID = "QmY7JB6MQXhxHvq7dBDh4HpbH29v4yE9JRadAVpndvzySN";
            Addrs = [ "/dns4/node3.preload.ipfs.io/tcp/4001" "/dns4/node3.preload.ipfs.io/udp/4001/quic" ];
          }
          {
            ID = "QmcZf59bWwK5XFi76CZX8cbJ4BhTzzA3gU1ZjYZcYW3dwt";
            Addrs = [ "/dns4/nrt-1.bootstrap.libp2p.io/tcp/4001" "/dns4/nrt-1.bootstrap.libp2p.io/udp/4001/quic" ];
          }
          {
            ID = "QmbLHAnMoJPWSCR5Zhtx6BHJX9KiKNN6tpvbUcqanj75Nb";
            Addrs = [ "/dns4/ams-2.bootstrap.libp2p.io/tcp/4001" "/dns4/ams-2.bootstrap.libp2p.io/udp/4001/quic" ];
          }
          {
            ID = "QmZa1sAxajnQjVM8WjWXoMbmPd7NsWhfKsPkErzpm9wGkp";
            Addrs = [ "/dns4/sjc-2.bootstrap.libp2p.io/tcp/4001" "/dns4/sjc-2.bootstrap.libp2p.io/udp/4001/quic" ];
          }
          {
            ID = "QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN";
            Addrs = [ "/dns4/sjc-1.bootstrap.libp2p.io/tcp/4001" "/dns4/sjc-1.bootstrap.libp2p.io/udp/4001/quic" ];
          }
          {
            ID = "QmQCU2EcMqAqQPR2i9bChDtGNJchTbq5TbXJJ16u19uLTa";
            Addrs = [ "/dns4/ewr-1.bootstrap.libp2p.io/tcp/4001" "/dns4/ewr-1.bootstrap.libp2p.io/udp/4001/quic" ];
          }
        ];
      };
      Addresses = {
        #Announce = [
        #  "/dnsaddr/ipfs.scalable.io"
        #  "/dns4/ipfs.scalable.io/tcp/443/wss"
        #  "/dns6/ipfs.scalable.io/tcp/443/wss"
        #  "/ip4/172.104.14.163/udp/4001/quic"
        #  "/ip6/2600:3c03::f03c:91ff:fed8:373c/udp/4001/quic"
        #  "/ip4/172.104.14.163/udp/4001/quic-v1"
        #  "/ip6/2600:3c03::f03c:91ff:fed8:373c/udp/4001/quic-v1"
        #  "/ip4/172.104.14.163/udp/4001/quic-v1/webtransport"
        #  "/ip6/2600:3c03::f03c:91ff:fed8:373c/udp/4001/quic-v1/webtransport"
        #  #"/ip4/172.104.14.163/tcp/4001"
        #  #"/ip4/172.104.14.163/udp/4001/quic"
        #];
        Datastore = {
          StorageMax = "10GB";
          StorageGCWatermark = 90;
          GCPeriod = "1h";
          Spec = {
            child = {
              path = "badgerds";
              syncWrites = false;
              truncate = true;
              type = "badgerds";
            };
            prefix = "badger.datastore";
            type = "measure";
          };
          HashOnRead = false;
          BloomFilterSize = 0;
        };
      };
      Swarm = {
        ConnMgr = {
          HighWater = 10000;
          LowWater = 1000;
        };
        Transports.Network.TCP = false;
      };
    };
    extraFlags = [ "--enable-namesys-pubsub" "--migrate" "--init-profile" "badgerds" ];
  };

}
