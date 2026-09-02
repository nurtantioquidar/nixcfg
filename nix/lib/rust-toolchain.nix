{ pkgs }:

pkgs.rust-bin.stable.latest.default.override {
  extensions = [
    "rust-analyzer"
    "rust-src"
  ];
}
