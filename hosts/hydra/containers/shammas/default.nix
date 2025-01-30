{ config, pkgs, ... }:
{
  #services.nginx.virtualHosts."test.nycr.chat" = {
  #  forceSSL = true;
  #  enableACME = true;
  #  locations."/".proxyPass = "http://192.168.55.10/";
  #};

  containers.shammas = {
    autoStart = true;
    hostBridge = "virtbr0";
    privateNetwork = true;
    extraFlags = [ "-U" ];
    enableTun = true;

    config =
      { ... }:
      {
        nixpkgs.pkgs = pkgs;
        imports = [ (import ../common.nix "shammas") ];

        networking.firewall.allowedUDPPorts = [ 443 ];

        services.nginx = {
          enable = true;
          package = pkgs.nginxQuic;
          virtualHosts = {
            "shamm.as" = {
              serverAliases = [ "www.shamm.as" "scalable.io" "www.scalable.io" ];
              forceSSL = true;
              enableACME = true;
              quic = true;
              root = ./static_sites/shamm.as;
              default = true;
            };
            "blog.shamm.as" = {
              forceSSL = true;
              enableACME = true;
              quic = true;
              root = pkgs.blog_shamm_as;
            };
            "hackerfoundation.org" = {
              serverAliases = [ "www.hackerfoundation.org" ];
              forceSSL = true;
              enableACME = true;
              quic = true;
              root = ./static_sites/hackerfoundation.org;
            };
            "openpgpkey.shamm.as" = {
              serverAliases = [ "www.openpgpkey.shamm.as" ];
              forceSSL = true;
              enableACME = true;
              quic = true;
              root = ./static_sites/openpgpkey.shamm.as;
            };
            "xn--xj8h.ws" = {
              serverAliases = [ "www.xn--xj8h.ws" ];
              forceSSL = true;
              enableACME = true;
              quic = true;
              root = ./static_sites/xn--xj8h.ws;
            };
          };
        };
      };
  };
}
