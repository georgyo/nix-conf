{
  description = "HOME";

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    flake-file.url = "github:vic/flake-file";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "";
    };

    myemacs = {
      url = "github:georgyo/emacs-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    avalon = {
      url = "github:georgyo/avalon";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    blog_shamm_as = {
      url = "github:georgyo/blog.shamm.as";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cloudflare_ips_v4 = {
      url = "https://www.cloudflare.com/ips-v4";
      flake = false;
    };
    cloudflare_ips_v6 = {
      url = "https://www.cloudflare.com/ips-v6";
      flake = false;
    };
  };
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
  # outputs =

  #     outputsBuilder = channels: {
  #       formatter = channels.default.nixfmt-tree;
  #       # legacyPackages = channels.default;
  #       packages = {

  #         inherit (channels.default) blog_shamm_as;

  #         home-env =
  #           with channels.cudaDefault;
  #           buildEnv {
  #             name = "home-env";
  #             extraOutputsToInstall = [
  #               "man"
  #               "doc"
  #             ];
  #             paths = with pkgs; [
  #               buck2
  #               git-bug
  #               git-absorb
  #               hugo
  #               hydra-check
  #               nix-index
  #               nix-update
  #               nixd
  #               nixf
  #               nixfmt-rfc-style
  #               usql
  #               watchman
  #             ];
  #             postBuild = ''
  #               if [ -x $out/bin/install-info -a -w $out/share/info ]; then
  #                 shopt -s nullglob
  #                 for i in $out/share/info/*.info $out/share/info/*.info.gz; do
  #                     $out/bin/install-info $i $out/share/info/dir
  #                 done
  #               fi
  #             '';

  #           };

  #         opengl_dir = channels.default.callPackage (
  #           {
  #             buildEnv,
  #             mesa,
  #             linuxPackages,
  #           }:
  #           buildEnv {
  #             name = "opengl_dir";
  #             paths = [
  #               mesa.drivers
  #               linuxPackages.nvidia_x11.out
  #             ];

  #           }
  #         ) { };
  #       };

  #       devShell =
  #         with channels.default;
  #         mkShell {
  #           nativeBuildInputs = [
  #             sops-import-keys-hook
  #             age
  #           ];

  #           sopsPGPKeyDirs = [
  #             "./keys/hosts"
  #             "./keys/users"
  #           ];
  #         };
  #     };

  #   };

}
