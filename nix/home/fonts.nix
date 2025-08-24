{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Font management tools
    fontconfig
  ];

  # Fonts are installed via nix-darwin fonts.packages in configuration.nix
  # This provides better system integration than manual installation

  # Configure fontconfig to recognize the fonts
  home.file.".config/fontconfig/fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <!-- System-wide fonts directory (managed by nix-darwin) -->
      <dir>/run/current-system/sw/share/fonts</dir>
      
      <!-- User fonts directory -->
      <dir>~/Library/Fonts</dir>
      
      <!-- Alias for Atlassian fonts -->
      <alias>
        <family>Atlassian Mono</family>
        <prefer>
          <family>AtlassianMono-latin</family>
        </prefer>
      </alias>
      
      <alias>
        <family>Atlassian Sans</family>
        <prefer>
          <family>AtlassianSans-latin</family>
        </prefer>
      </alias>
    </fontconfig>
  '';
}