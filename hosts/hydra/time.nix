{
  config,
  lib,
  pkgs,
  ...
}:

{

  # Set your time zone.
  time.timeZone = "America/New_York";
  time.hardwareClockInLocalTime = true;

  services.chrony = {
    enable = true;
    servers = [
      "time1.google.com"
      "time2.google.com"
      "time3.google.com"
      "time4.google.com"
      "tick.nyu.edu"
      "tock.nyu.edu"
    ];
    extraConfig = ''
      minsources 5
      combinelimit 5
      pool 0.nixos.pool.ntp.org iburst
      pool 1.nixos.pool.ntp.org iburst
      pool 2.nixos.pool.ntp.org iburst
      pool 3.nixos.pool.ntp.org iburst
      pool time.cloudflare.com iburst
    '';
  };

  services.ntp = {
    enable = false;
    servers = [
      "time1.google.com"
      "time2.google.com"
      "time3.google.com"
      "time4.google.com"
      "tick.nyu.edu"
      "tock.nyu.edu"
      "time.cloudflare.com"
    ];
    extraConfig = ''
      statsdir /var/lib/ntp/
      statistics loopstats peerstats clockstats
      filegen loopstats file loopstats type day enable
      filegen peerstats file peerstats type day enable
      filegen clockstats file clockstats type day enable
      logconfig =syncall +clockall +peerall +sysall

      tos minsane 2
    '';
    extraFlags = [ "-N" ];
  };
}
