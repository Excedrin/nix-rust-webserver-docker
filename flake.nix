{
  description = "A Rust web server including a NixOS module";

  inputs = {
    # Nixpkgs / NixOS version to use.
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    #nixpkgs.url = "github:nixos/nixpkgs/ad0b5eed1b6031efaed382844806550c3dcb4206";
    import-cargo.url = "github:edolstra/import-cargo";
    nix2container.url = "github:nlewo/nix2container";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    import-cargo,
    nix2container,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        nix2containerPkgs = nix2container.packages.${system};

        # to work with older version of flakes
        lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

        # Generate a user-friendly version number.
        version = "${builtins.substring 0 8 lastModifiedDate}-${self.shortRev or "dirty"}";

        # A Nixpkgs overlay.
        overlay = final: prev: {
          rust-web-server = with final;
            final.callPackage ({inShell ? false}:
              stdenv.mkDerivation rec {
                name = "rust-web-server-${version}";

                # In 'nix develop', we don't need a copy of the source tree
                # in the Nix store.
                src =
                  if inShell
                  then null
                  else ./.;

                buildInputs =
                  [
                    libiconv
                    rustc
                    cargo
                  ]
                  ++ (
                    if inShell
                    then [
                      # In 'nix develop', provide some developer tools.
                      rustfmt
                      clippy
                    ]
                    else [
                      (import-cargo.builders.importCargo {
                        lockFile = ./Cargo.lock;
                        inherit pkgs;
                      })
                      .cargoHome
                    ]
                  );

                target = "--release";

                buildPhase = "cargo build ${target} --frozen --offline";

                doCheck = true;

                checkPhase = "cargo test ${target} --frozen --offline";

                installPhase = ''
                  mkdir -p $out
                  cargo install --frozen --offline --path . --root $out
                  rm $out/.crates.toml
                '';
              }) {};
        };
        pkgs = import nixpkgs {
          inherit system;
          overlays = [overlay];
        };
      in {
        packages.default = nix2containerPkgs.nix2container.buildImage {
          name = "rust-web-server";
          tag = version;
          copyToRoot = pkgs.buildEnv {
            name = "root";
            paths = [pkgs.bash pkgs.rust-web-server];
            pathsToLink = ["/bin"];
          };
          config = {
            entrypoint = ["${pkgs.rust-web-server}/bin/rust-web-server"];
          };
          maxLayers = 40;
          layers = [
            (nix2containerPkgs.nix2container.buildLayer {
              deps = [pkgs.rust-web-server];
            })
          ];
        };
      }
    );
}
