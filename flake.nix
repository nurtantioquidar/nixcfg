{
  description = "Nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";

    nix-darwin.url = "github:lnl7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, flake-utils, nixpkgs, rust-overlay, ... }: let
    overlays = [ (import rust-overlay) (import ./nix/overlays) ];

    nixpkgsConfig = {
      inherit overlays;

      config.allowUnfree = true;
    };
  in {
    darwinConfigurations =
      let
        inherit (inputs.nix-darwin.lib) darwinSystem;
      in {
        "styx" = darwinSystem {
          system = "aarch64-darwin";

          specialArgs = { inherit inputs; };

          modules = [
            inputs.nix-homebrew.darwinModules.nix-homebrew
            inputs.home-manager.darwinModules.home-manager
            ./nix/hosts/mbp/configuration.nix
            {
              nixpkgs = nixpkgsConfig;

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.users.hades = import ./nix/home/home.nix;
            }
          ];
        };
      };

    nixosConfigurations =
      let
        inherit (nixpkgs.lib) nixosSystem;
      in {
        "wsl" = nixosSystem {
          system = "x86_64-linux";

          specialArgs = { inherit inputs; };

          modules = [
            inputs.nixos-wsl.nixosModules.wsl
            inputs.home-manager.nixosModules.home-manager
            ./nix/hosts/wsl/configuration.nix
            {
              nixpkgs = nixpkgsConfig;

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.hades = import ./nix/home/home.nix;
            }
          ];
        };
      };
  } // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system overlays; };
    in
    {
      packages = pkgs;

      devShell = with pkgs; mkShell {
        buildInputs = [
          nil
          statix
          nixpkgs-fmt
          rust-bin.beta.latest.default
        ];
      };
    }
  );
}
