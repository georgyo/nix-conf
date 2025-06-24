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
    "time1.apple.com"
    "time2.apple.com"
    "time3.apple.com"
    "time4.apple.com"
    "time5.apple.com"
    "time6.apple.com"
    "time7.apple.com"
    "time1.facebook.com"
    "time2.facebook.com"
    "time3.facebook.com"
    "time4.facebook.com"
    "time5.facebook.com"
    "time1.google.com"
    "time2.google.com"
    "time3.google.com"
    "time4.google.com"
    "time.cloudflare.com"
    "time.aws.com"
    "time.nist.gov"
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
