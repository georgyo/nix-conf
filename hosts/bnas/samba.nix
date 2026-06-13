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
    nsswins = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "bnas";
        "netbios name" = "bnas";
        "security" = "user";
        # Unknown/anonymous logins fall back to the guest account instead of
        # being rejected, enabling read-only guest access on shares below.
        "map to guest" = "bad user";
        "unix password sync" = "yes";
        "usershare path" = "/var/lib/samba/usershares";
        "usershare max shares" = "100";
        "usershare allow guests" = "yes";
        "usershare owner only" = "no";
        "guest account" = "nobody";
        "invalid users" = [
          "root"
        ];
      };
      homes = {
        "browseable" = "no";
        "writable" = "yes";
      };
      # Explicit share that presents the connecting user's own home dir as
      # "home" (browseable), alongside the per-username [homes] share above.
      "home" = {
        "path" = "%H";
        "browseable" = "yes";
        "writable" = "yes";
        "guest ok" = "no";
        "valid users" = "%U";
      };
      "media" = {
        "path" = "/mnt/data/media";
        "browseable" = "yes";
        # Read-only for guests; any authenticated user may write. All normal
        # login users share the "users" primary group, while the guest account
        # (nobody) does not, so @users == "all non-guest users".
        "read only" = "yes";
        "guest ok" = "yes";
        "write list" = "@users";
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

  # For mount.cifs, required unless domain name resolution is not needed.
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."/mnt/airportsilom" = {
    device = "//airportsilom.tail414d48.ts.net/hypervault-georgyo";
    fsType = "cifs";
    options =
      let
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      in
      [ "${automount_opts},credentials=${config.age.secrets.airportsilom_credentials.path}" ];
  };
}
