# Exposes `packages.flake-inputs`: a derivation whose closure contains the
# source tree of every flake input, recursively (inputs of inputs, ...).
#
# Why: when a locked input has a known narHash, Nix computes its store path
# and asks the substituters for it *before* fetching from GitHub or wherever.
# Building this package and pushing its closure to the binary cache therefore
# makes later `nix build`/`nixos-rebuild` on other machines pull the inputs
# from the cache instead of the original source.
#
# Layout: a flat directory with one symlink per unique input, named by its
# dotted path in the input graph (e.g. `nixpkgs`, `agenix.systems`). Inputs
# deduplicated via `follows` show up once, under the shallowest name they
# were found at. The flat layout matters: `agenix` is itself a symlink into
# the read-only store, so nothing could be created "inside" it.
{ inputs, lib, ... }:
let
  # Breadth-first walk over the input graph.
  #
  # `seen` is an attrset keyed by store path (context stripped, since attr
  # names may not carry string context) whose values are linkFarm entries.
  key = i: builtins.unsafeDiscardStringContext (toString i.outPath);

  # The root flake itself. Reachable as `self` and through every
  # `follows = ""` edge; never worth caching, and changes on every commit.
  root = key inputs.self;

  collect =
    seen: prefix: attrs:
    let
      fresh = lib.filterAttrs (_: i: i ? outPath && key i != root && !(seen ? ${key i})) attrs;

      seen' =
        seen
        // lib.mapAttrs' (
          name: i:
          lib.nameValuePair (key i) {
            name = "${prefix}${name}";
            path = i.outPath;
          }
        ) fresh;
    in
    lib.foldl' (
      acc: name:
      let
        i = fresh.${name};
      in
      if i ? inputs then collect acc "${prefix}${name}." i.inputs else acc
    ) seen' (lib.attrNames fresh);

  entries = lib.attrValues (collect { } "" inputs);
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.flake-inputs = pkgs.linkFarm "flake-inputs" entries;
    };
}
