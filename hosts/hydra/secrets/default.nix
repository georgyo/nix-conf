{ ... }:
{
  sops = {
    age = {
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
    defaultSopsFile = ./secrets/secrets.yaml;
  };
}
