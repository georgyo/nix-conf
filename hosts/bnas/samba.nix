{
  config,
  lib,
  pkgs,
  ...
}:

{
  users.groups.media = { };
  services.samba = {
    enable = true;
    package = pkgs.samba.override { enableMDNS = true; };
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "bnas";
        "netbios name" = "bnas";
        "security" = "user";
        "unix password sync" = "yes";
        "usershare path" = "/var/lib/samba/usershares";
        "usershare max shares" = "100";
        "usershare allow guests" = "yes";
        "usershare owner only" = "no";
        "guest account" = "nobody";
      };
      homes = {
        "browseable" = "no";
        "writable" = "yes";
      };
      "media" = {
        "path" = "/mnt/data/media";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "1755";
        "force user" = "nobody";
        "force group" = "media";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
}
