{
  description = "Mutation testing talk demo: 100% coverage, 0% mutation score";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-darwin" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };
        hs = pkgs.haskellPackages;
        demo = hs.callCabal2nix "mutation-coverage-demo" ./. { };
      in {
        packages.default = demo;

        # `nix build .#checks.<system>.default` (or `nix flake check`) builds
        # the library and runs the test suite -- doCheck is on by default for
        # Haskell packages built this way.
        checks.default = demo;

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.cabal-install
            pkgs.haskell-language-server
            # hpc ships with GHC itself.
            (hs.ghcWithPackages (p: [ p.hspec ]))
          ];
        };
      });
}
