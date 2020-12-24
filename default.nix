final: prev:
let
  poetry2nix = prev.poetry2nix;

  # have to pass the pinned nixpkgs from nixops
  # else getting different libc versions in dependee libraries
  # e.g. ImportError: /nix/store/bqbg6hb2jsl3kvf6jgmgfdqy06fpjrrn-glibc-2.30/lib/libc.so.6: version `GLIBC_2.32' not found (required by /nix/store/scsk0fl5rgnqy53j6dfl55srzirckbmw-libvirt-6.6.0/lib/libvirt.so.0)
  nixops-nixpkgs = (import (import ./nixops).inputs.nixpkgs.outPath {
    overlays =
      [
        (final: prev: {
          # have to merge in the newer poetry2nix 1.14.0
          # else fresher poetry.locks of plugins will cause their build to fail with
          # ERROR: No matching distribution found for typeguard<3.0.0,>=2.7.1 (from nixops==2.0.0)
          # https://github.com/nix-community/poetry2nix/issues/208
          poetry2nix = poetry2nix.override {
            # have to override pkgs, else when installing plugins,
            # pip will try to fetch nixops from git because of
            # mismatching python versions (i guess) and fail.
            pkgs = final;
          };
        })
      ];
  });
in
{
  nixops-hetzner = prev.callPackage ./nixops-hetzner {
    pkgs = nixops-nixpkgs;
  };

  nixops-libvirtd = prev.callPackage ./nixops-libvirtd {
    pkgs = nixops-nixpkgs;
  };

  nixops = nixops-nixpkgs.python3.withPackages (ps: [
    final.nixops-libvirtd
    final.nixops-hetzner
  ]);
}
