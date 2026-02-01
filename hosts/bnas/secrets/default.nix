{ ... }:
{
  age.secrets = {
    wg-quick.file = ./wg-quick.age;
    local-wg-key.file = ./local-wg-key.age;
    "seedns/seed.yml".file = ./wg-netns.age;
    airportsilom_credentials.file = ./airportsilom_credentials.age;
    # sabnzbd_settings = ./sabnzbd.ini.age;
    CF_API_KEY = {
      mode = "400";
      owner = "traefik";
      group = "traefik";
      file = ./CF_API_KEY.age;
    };
  };
}
