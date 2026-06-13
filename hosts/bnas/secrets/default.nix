{ ... }:
{
  age.secrets = {
    wg-quick.file = ./wg-quick.age;
    local-wg-key.file = ./local-wg-key.age;
    "seedns/seed.yml".file = ./wg-netns.age;
    airportsilom_credentials.file = ./airportsilom_credentials.age;
    # Read by the traefik-forward-auth service via systemd LoadCredential,
    # so it can stay root-only (agenix default 0400) rather than world-readable.
    traefik-forward-auth.file = ./traefik-forward-auth.age;
    CF_API_KEY = {
      mode = "400";
      owner = "traefik";
      group = "traefik";
      file = ./CF_API_KEY.age;
    };
  };
}
