virtualHost:
{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.httpd.extraModules = [ "remoteip" ];
  services.httpd.virtualHosts.${virtualHost}.extraConfig =
    "RemoteIPHeader CF-Connecting-IP\n"
    + (lib.strings.concatMapStrings (x: "RemoteIPTrustedProxy ${x}\n") pkgs.cloudflare_ips_v4)
    + (lib.strings.concatMapStrings (x: "RemoteIPTrustedProxy ${x}\n") pkgs.cloudflare_ips_v6);
}
