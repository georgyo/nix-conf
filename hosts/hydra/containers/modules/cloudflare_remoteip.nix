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

  services.nginx.appendHttpConfig =
    "real_ip_header CF-Connecting-IP;\n"
    + (lib.strings.concatMapStrings (x: "set_real_ip_from ${x};\n") pkgs.cloudflare_ips_v4)
    + (lib.strings.concatMapStrings (x: "set_real_ip_from ${x};\n") pkgs.cloudflare_ips_v6);

}
