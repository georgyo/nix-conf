# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
inputs:
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./secrets
    ./traefik.nix
    ./plex.nix
    ./immich.nix
    ./packages/wg-netns
    ./seed.nix
    ./local-wireguard.nix
    ./samba.nix
    ./home-assistant.nix
    ./networking.nix
    ./smart.nix
  ];

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "plexmediaserver"
      "unrar"
    ];
  programs = {
    zsh = rec {
      enable = true;
      #promptInit = "";
      enableBashCompletion = true;
      shellInit = ''
        source ${pkgs.grml-zsh-config}/etc/zsh/zshrc
      '';
      loginShellInit = shellInit;
      interactiveShellInit = shellInit;

    };

    git.enable = true;
    tmux.enable = true;
    bash.completion.enable = true;
    mosh.enable = true;
    mtr.enable = true;
    nh = {
      enable = true;
      flake = "/etc/nixos";
    };
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      withNodeJs = true;
      configure = {
        customRC = '''';
        customLuaRC = ''
          vim.g.coq_settings = {
              auto_start = true,
          }
            local coq = require "coq" -- add this

          vim.lsp.config('nixd', coq.lsp_ensure_capabilities())
            vim.lsp.enable('nixd')
          vim.opt.completeopt = { "menuone", "noselect", "popup" } 

        '';
        packages.all.start = with pkgs.vimPlugins; [
          # coc-nvim
          coq_nvim
          nvim-lspconfig
          nvim-treesitter.withAllGrammars # to install all grammars (including nix)
        ];
      };
    };
    nix-ld.enable = true;
  };

  nix.extraOptions = ''
    experimental-features = nix-command flakes ca-derivations fetch-tree

  '';

  security.pam.zfs.enable = true;

  environment.systemPackages = with pkgs; [
    dool
    htop
    tig
    curl
    iptables
    fd

    nixfmt
    nixfmt-tree
    nix-output-monitor
    nixd

    wireguard-tools
    ripgrep
    atuin

  ];

  services.openssh = {
    enable = true;
  };

  services.below.enable = true;

  services.nfs.server.enable = true;
  services.nfs.server.exports = ''/mnt/data/media        192.168.1.118(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)	192.168.1.148(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)	192.168.1.0/24(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)	192.168.0.0/24(rw,async,no_wdelay,crossmnt,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)'';

  users.users.root.shell = pkgs.zsh;

  users.extraUsers.shammas = {
    isNormalUser = true;
    createHome = true;
    uid = 1000;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHIR85OQWCKZz8AofJcLO48UnvVlXZaKGlelYOx6WITP shammas@glap"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKrAxJtkMUjVhFJ2o5UPXbQLn8Q92c3g4xuCjCBtNmnz shammas@bigtower"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKhItTwa8QPZ+HuLEzAtYzD5U+HmE53QAsahdjHGx8rm 1password"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGF99yGzL9/m2X8W1ea6gjifSY4s2dinLhUijuYbgfaX georg@DESKTOP-AIUJF2H"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOnJ+uG3t57MAdhYyvZhYULS5XYkqfAxWh//iBGblVaz shammas@gtmlap"
    ];

  };

  users.extraUsers.nowossjolka = {
    isNormalUser = true;
    createHome = true;
    uid = 1001;
    shell = pkgs.zsh;
    extraGroups = [ ];
    openssh.authorizedKeys.keys = [ ];
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?
  #
  #

  containers.seed.config = {
    imports = [
      inputs.agenix.nixosModules.default
    ];
  };
}
