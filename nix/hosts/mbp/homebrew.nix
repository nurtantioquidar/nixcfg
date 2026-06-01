{ inputs, ... }:

{
  # One-time bootstrap only: prefix ownership (user-owned /opt/homebrew),
  # Rosetta, migration, and pinned tap checkouts. Package management
  # (taps/brews/casks) lives in the user-scoped Home Manager profile at
  # nix/home/homebrew.nix, applied via `home-manager switch` without sudo.
  nix-homebrew = {
    enable = true;

    enableRosetta = true;

    user = "hades";

    autoMigrate = true;

    taps = {
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "manaflow-ai/homebrew-cmux" = inputs.homebrew-cmux;
    };
  };
}
