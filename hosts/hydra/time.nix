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

  networking.timeServers = [
    "time.google.com"
    "time.aws.com"
    "time.facebook.com"
    "time.windows.com"
    "time.apple.com"
    "time.nist.gov"
    "time1.google.com"
    "time2.google.com"
    "time3.google.com"
    "time4.google.com"
    "time.cloudflare.com"
    "0.nixos.pool.ntp.org"
    "1.nixos.pool.ntp.org"
    "2.nixos.pool.ntp.org"
    "3.nixos.pool.ntp.org"
  ];

  services.chrony = {
    enable = true;
    extraConfig = ''
      minsources 5
      combinelimit 5
    '';
  };

  services.ntp = {
    enable = false;
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
