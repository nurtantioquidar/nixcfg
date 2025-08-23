{ stdenv, lib }:

stdenv.mkDerivation rec {
  pname = "atlassian-fonts";
  version = "1.0.0";

  src = ../../../assets/fonts;

  installPhase = ''
    runHook preInstall
    
    install -Dm644 *.ttf -t $out/share/fonts/truetype/
    
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