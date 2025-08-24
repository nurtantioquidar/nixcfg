{ lib, stdenvNoCC }:

stdenvNoCC.mkDerivation rec {
  pname = "atlassian-mono";
  version = "1.0";

  # Reference local font files
  src = ../../assets/fonts;

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/share/fonts/truetype/atlassian-mono
    cp -v $src/AtlassianMono-latin.ttf $out/share/fonts/truetype/atlassian-mono/
    cp -v $src/AtlassianSans-latin.ttf $out/share/fonts/truetype/atlassian-mono/
  '';

  meta = with lib; {
    description = "Atlassian Mono font packaged for nix-darwin";
    longDescription = ''
      Atlassian Mono is based on JetBrains Mono but customized by Atlassian.
      This package includes both Atlassian Mono and Atlassian Sans fonts.
    '';
    license = licenses.ofl; # Using OFL like JetBrains Mono
    platforms = platforms.all;
  };
}