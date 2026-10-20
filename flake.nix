{
  description = "Raid night flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # mdbook-admonish (1.20.0, the latest release as of writing) doesn't yet
    # speak mdbook 0.5's preprocessor protocol: https://github.com/tommilligan/mdbook-admonish/issues/233
    # Pin mdbook + mdbook-admonish together from a known-compatible nixpkgs
    # release until that's fixed upstream.
    nixpkgs-mdbook.url = "github:nixos/nixpkgs?ref=nixos-24.11";
  };

  outputs = { self, nixpkgs, flake-utils, nixpkgs-mdbook }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pkgsMdbook = nixpkgs-mdbook.legacyPackages.${system};
        # mdbook-tabs isn't packaged in nixpkgs. 0.2.3 is the last release
        # built against mdbook 0.4 (0.3+ requires mdbook 0.5).
        mdbook-tabs = pkgs.rustPlatform.buildRustPackage rec {
          pname = "mdbook-tabs";
          version = "0.2.3";
          src = pkgs.fetchCrate {
            inherit pname version;
            hash = "sha256-dO1+rGiu45qSOXw9xiuQXE7G9faV+SxSXxCFkD27E6A=";
          };
          cargoHash = "sha256-0HF7hRWe6qivY0R/LAfIj0qvXG1ct1+5boImaRfd/Dg=";
          doCheck = false;
        };
        mdbookTools = [ pkgsMdbook.mdbook pkgsMdbook.mdbook-admonish mdbook-tabs ];
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          src = ./.;
          name = "raid-night";
          nativeBuildInputs = mdbookTools;

            buildPhase = ''
              mdbook build
            '';

            installPhase = ''
              mkdir -p $out
              cp -r book/* $out/
            '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = mdbookTools;
          shellHook = ''
            alias run="mdbook serve"
            echo "Raid night!"
          '';
        };
      }
    );
}
