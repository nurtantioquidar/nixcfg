{ lib, stdenvNoCC }:

stdenvNoCC.mkDerivation rec {
  pname = "atlassian-fonts";
  version = "1.0.0";

  # Use local font files
  src = ../../../assets/fonts;

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/share/fonts/truetype/atlassian
    cp $src/*.ttf $out/share/fonts/truetype/atlassian/
  '';

  meta = with lib; {
    description = "Atlassian fonts (Mono and Sans)";
    homepage = "https://atlassian.design/foundations/typography";
    license = licenses.ofl;
    platforms = platforms.all;
    maintainers = [ ];
  };
}