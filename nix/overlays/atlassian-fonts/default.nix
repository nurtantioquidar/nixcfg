{ stdenv, lib }:

stdenv.mkDerivation rec {
  pname = "atlassian-fonts";
  version = "1.0.0";

  src = ../../../assets/fonts;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    
    # Install fonts in the root of share/fonts for better macOS recognition
    mkdir -p $out/share/fonts
    cp -v $src/*.ttf $out/share/fonts/
    
    # Also create the standard truetype directory structure
    mkdir -p $out/share/fonts/truetype
    cp -v $src/*.ttf $out/share/fonts/truetype/
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "Atlassian font family";
    longDescription = ''
      A collection of Atlassian fonts including Atlassian Mono and Atlassian Sans.
    '';
    platforms = platforms.all;
  };
}