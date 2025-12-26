{
  description = "Build a cargo project without extra checks";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane.url = "github:ipetkov/crane";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      crane,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        craneLib = crane.mkLib pkgs;

        # Common arguments can be set here to avoid repeating them later
        # Note: changes here will rebuild all dependency crates
        commonArgs = {
          src = craneLib.cleanCargoSource ./.;
          strictDeps = true;

          buildInputs = [
            pkgs.vulkan-loader
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            pkgs.libiconv
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
            pkgs.alsa-lib
            pkgs.libxkbcommon
            pkgs.wayland
          ];
        };

        artCrate = craneLib.buildPackage (
          commonArgs
          // {
            cargoArtifacts = craneLib.buildDepsOnly commonArgs;

            # Additional environment variables or build phases/hooks can be set
            # here *without* rebuilding all dependency crates
            # MY_CUSTOM_VAR = "some value";
          }
        );
      in
      {
        checks = {
          artCrateCheck = artCrate;
        };

        packages.default = artCrate;

        apps.default = flake-utils.lib.mkApp {
          drv = artCrate;
        };

        devShells.default = craneLib.devShell rec {
          # Inherit inputs from checks.
          checks = self.checks.${system};

          # Additional dev-shell environment variables can be set directly
          # MY_CUSTOM_DEVELOPMENT_VAR = "something else";

          LD_LIBRARY_PATH =
            builtins.foldl' (a: b: "${a}:${b}/lib") "${pkgs.vulkan-loader}/lib" packages;
          # Extra inputs can be added here; cargo and rustc are provided by default.
          packages = with pkgs; [
            alsa-lib
            cmake
            fontconfig
            freetype
            libGL
            libxkbcommon
            pkg-config
            vulkan-loader
            vulkan-validation-layers
            wayland
            wayland-protocols
          ];
        };
      }
    );
}
