{ pkgs, lib, ... }:

{
  home = {
    packages = [ pkgs.geist-font ];

    file.".config/zed/settings.json" = lib.mkIf pkgs.stdenv.isDarwin {
      text = builtins.toJSON {
        auto_install_extensions = {
          catppuccin = true;
          dockerfile = true;
          html = true;
          make = true;
          nix = true;
        };
        base_keymap = "VSCode";
        languages = {
          Nix.language_servers = [ "nil" ];
          Python = {
            language_servers = [ "ty" "ruff" ];
            code_actions_on_format."source.organizeImports.ruff" = true;
            formatter.language_server.name = "ruff";
          };
        };
        project_panel.dock = "left";
        theme = "Catppuccin Mocha";
        ui_font_family = "Geist";
        ui_font_size = 14;
        buffer_font_family = "Geist Mono";
        buffer_font_weight = 400;
        buffer_font_size = 12;
        buffer_line_height = "standard";
        terminal.font_family = "SF Mono Terminal";
        terminal.font_weight = 400;
        terminal.font_size = 12;
      };
    };

    # Home Manager's automatic font copy uses a nested directory. Put Zed's
    # fonts directly in the macOS user font directory as regular files,
    # including SF Mono Terminal, which is bundled privately with Terminal.app.
    activation.installZedFonts = lib.mkIf pkgs.stdenv.isDarwin (
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$HOME/Library/Fonts"
        for font in ${pkgs.geist-font}/share/fonts/opentype/*.otf /System/Applications/Utilities/Terminal.app/Contents/Resources/Fonts/SFMono*-Terminal.ttf; do
          target="$HOME/Library/Fonts/''${font##*/}"
          if [ -L "$target" ]; then
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm "$target"
          fi
          if ! /usr/bin/cmp -s "$font" "$target"; then
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0644 "$font" "$target"
          fi
        done
      ''
    );
  };
}
