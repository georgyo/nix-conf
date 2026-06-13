{
  lib,
  buildGoModule,
  fetchFromGitHub,
  go_1_26,
  tailwindcss_4,
  terser,
}:
buildGoModule.override { go = go_1_26; } (finalAttrs: {
  pname = "traefik-forward-auth";
  version = "4.8.0";

  src = fetchFromGitHub {
    owner = "ItalyPaleAle";
    repo = "traefik-forward-auth";
    tag = "v${finalAttrs.version}";
    hash = "sha256-zDitge7xD1Euf7AWRNnLsL9ok9AIlkanGrxhW8AZrmc=";
  };

  vendorHash = "sha256-YzV7SW6ZaUV34iRMwWTTpCSxiNxDf4UfVPCtRqQvamg=";

  nativeBuildInputs = [
    tailwindcss_4
    terser
  ];

  # nixpkgs currently ships Go 1.26.0 but upstream go.mod requires 1.26.1.
  # Use --replace-quiet so this no-ops (rather than failing the build) once
  # upstream bumps go.mod or nixpkgs catches up to 1.26.1.
  postPatch = ''
    substituteInPlace go.mod --replace-quiet "go 1.26.1" "go 1.26.0"
  '';

  # Build the embedded client assets before Go compilation
  preBuild = ''
    mkdir -p client/dist
    tailwindcss --minify --cwd client/src -i style.css -o ../dist/style.css
    cp client/src/*.html.tpl client/dist/
    for f in client/dist/*.html.tpl; do
      sed -i 's/^[[:space:]]*//g' "$f"
    done
    terser client/src/icons.js -o client/dist/icons.js --compress --mangle
  '';

  subPackages = [ "cmd/traefik-forward-auth" ];

  doCheck = false;

  meta = {
    description = "Forward authentication service for Traefik, supporting OAuth2 and OpenID Connect";
    homepage = "https://github.com/ItalyPaleAle/traefik-forward-auth";
    license = lib.licenses.mit;
    mainProgram = "traefik-forward-auth";
  };
})
