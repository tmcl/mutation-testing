{
  description = "Mutation testing talk demo: stage 2 -- sydtest + mutation testing for real";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    sydtest.url = "github:NorfairKing/sydtest";

    # sydtest depends on opt-env-conf at a version/form not always present
    # in nixpkgs-unstable -- same workaround signs-alt uses, see the
    # sydtestDepsOverlay below.
    opt-env-conf.url = "github:NorfairKing/opt-env-conf?rev=25f47000a1ceba1fd11dd9634d126bb2b9416562";
    opt-env-conf.flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, sydtest, opt-env-conf, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-darwin" "aarch64-linux" ] (system:
      let
        # Pins opt-env-conf to a known-good version/source so sydtest's own
        # build doesn't depend on whatever happens to be in nixpkgs-unstable
        # this week. Mirrors signs-alt/nix/sydtest-deps-overlay.nix exactly.
        sydtestDepsOverlay = final: prev: {
          haskellPackages = prev.haskellPackages.override (old: {
            overrides = final.lib.composeExtensions (old.overrides or (_: _: { }))
              (hsSelf: _hsSuper: {
                opt-env-conf = hsSelf.callHackageDirect {
                  pkg = "opt-env-conf";
                  ver = "0.15.0.3";
                  sha256 = "sha256-9kb8tuNSqKeXjmeQbeG8H5VDdE+FOXuj8q7/4+Cr4Nk=";
                } { };
                opt-env-conf-test = hsSelf.callCabal2nix "opt-env-conf-test" "${opt-env-conf}/opt-env-conf-test" { };
              });
          });
        };

        pkgs = import nixpkgs {
          inherit system;
          overlays = [ sydtest.overlays.${system} sydtestDepsOverlay ];
        };
        hs = pkgs.haskellPackages;
        demo = hs.callCabal2nix "mutation-coverage-demo" ./. { };
      in {
        packages.default = demo;

        # `nix build .#checks.<system>.default` (or `nix flake check`) builds
        # the library and runs the test suite -- doCheck is on by default for
        # Haskell packages built this way.
        checks.default = demo;

        # `nix build .#checks.<system>.mutation` runs the real thing: builds
        # a mutant per mutation site, reruns the test suite against each,
        # and fails if any mutant survives.
        checks.mutation = pkgs.haskellPackages.sydtest.mutationCheck {
          name = "mutation-coverage-demo-mutation-check";
          packages = [ "mutation-coverage-demo" ];
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.cabal-install
            pkgs.haskell-language-server
            # hpc ships with GHC itself.
            (hs.ghcWithPackages (p: [ p.sydtest ]))
          ];
        };
      });
}
