{
  lib,
  stdenv,
  python3,
  fetchFromGitHub,
  wireguard-tools,
  iproute2,
  bash,
  makeWrapper,
  ...
}:

let
  python = python3.withPackages (ps: [
    ps.pyyaml
  ]);

  binPath = lib.makeBinPath [
    wireguard-tools
    iproute2
    python
  ];

in
stdenv.mkDerivation (finalAttrs: {
  pname = "wg-netns";
  version = "2.3.5";

  nativeBuildInputs = [ makeWrapper ];

  src = fetchFromGitHub {
    owner = "dadevel";
    repo = "wg-netns";
    tag = "v${finalAttrs.version}";
    hash = "sha256-hIlVHiqZCeTogLiapFyrHP/ytwNbJpgYU0AZvBtsoKI=";
  };

  installPhase = ''
    mkdir -p $out/bin
    cp wgnetns/main.py $out/bin/wg-netns
    chmod +x $out/bin/wg-netns

    wrapProgram $out/bin/wg-netns \
      --inherit-argv0 \
      --prefix PATH : ${binPath} \
      --set-default WG_SHELL "${bash}/bin/bash"

  '';

})
