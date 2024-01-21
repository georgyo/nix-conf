{ config, lib, pkgs, ... }@host:
with lib;

{
  options.shammtainers = {
    containers = mkOption { };

  }
