{
  description = "Nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";

    nix-darwin.url = "github:lnl7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";

    herdr = {
      url = "github:herdrdev/herdr/v0.8.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    homebrew-cmux = {
      url = "git+https://github.com/manaflow-ai/homebrew-cmux.git";
      flake = false;
    };

    homebrew-tinycast = {
      url = "github:abue-ammar/homebrew-tinycast";
      flake = false;
    };

    homebrew-aerospace = {
      url = "github:nikitabobko/homebrew-tap";
      flake = false;
    };

    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, flake-utils, nixpkgs, rust-overlay, ... }:
    let
      overlays = [ (import rust-overlay) inputs.herdr.overlays.default (import ./nix/overlays) ];

      nixpkgsConfig = {
        inherit overlays;

        config.allowUnfree = true;
      };
    in
    {
      darwinConfigurations =
        let
          inherit (inputs.nix-darwin.lib) darwinSystem;
          mkMacBook = configuration: darwinSystem {
            system = "aarch64-darwin";
            specialArgs = { inherit inputs; };
            modules = [
              inputs.nix-homebrew.darwinModules.nix-homebrew
              inputs.home-manager.darwinModules.home-manager
              configuration
              {
                nixpkgs = nixpkgsConfig;
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  backupFileExtension = "backup";
                  users.hades = import ./nix/home/home.nix;
                };
              }
            ];
          };
          styx = mkMacBook ./nix/hosts/mbp/configuration.nix;
          workMacBookAir = mkMacBook ./nix/hosts/mba/configuration.nix;
        in
        {
          "styx" = styx;
          "MAC-F0Q3XN9HR9" = styx;
          "MAC-YP2JJ9KNWT" = workMacBookAir;
          luna = darwinSystem {
            system = "aarch64-darwin";
            specialArgs = { inherit inputs; };
            modules = [
              inputs.home-manager.darwinModules.home-manager
              ./nix/hosts/mac-mini/configuration.nix
              {
                nixpkgs = nixpkgsConfig;
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  backupFileExtension = "backup";
                  users.kerberos = import ./nix/home/server.nix;
                };
              }
            ];
          };
        };

      homeConfigurations =
        let
          inherit (inputs.home-manager.lib) homeManagerConfiguration;

          system = "aarch64-darwin";
          pkgs = import nixpkgs ({ inherit system; } // nixpkgsConfig);
        in
        {
          hades = homeManagerConfiguration {
            inherit pkgs;

            extraSpecialArgs = { inherit inputs; };

            modules = [
              ./nix/home/home.nix
              {
                home = {
                  username = "hades";
                  homeDirectory = "/Users/hades";
                };
              }
            ];
          };
        };

      nixosConfigurations =
        let
          inherit (nixpkgs.lib) nixosSystem;
        in
        {
          "wsl" = nixosSystem {
            system = "x86_64-linux";

            specialArgs = { inherit inputs; };

            modules = [
              inputs.nixos-wsl.nixosModules.wsl
              inputs.home-manager.nixosModules.home-manager
              ./nix/hosts/wsl/configuration.nix
              {
                nixpkgs = nixpkgsConfig;

                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  users.hades = import ./nix/home/home.nix;
                };
              }
            ];
          };
        };
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system overlays; };
        rustToolchain = import ./nix/lib/rust-toolchain.nix { inherit pkgs; };
      in
      {
        legacyPackages = pkgs;

        devShells.default = with pkgs; mkShell {
          buildInputs = [
            nil
            statix
            nixpkgs-fmt
            rustToolchain
          ];

          RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
        };
      }
    );
}
