{ pkgs, ... }:
let
  zellijNoGhosttyQueries = (pkgs.writeShellScriptBin "zellij" ''
    ghostty_outer_tty=false

    if [ "''${TERM:-}" = "xterm-ghostty" ]; then
      ghostty_outer_tty=true
      export ZELLIJ_ORIGINAL_TERM="$TERM"
      export TERM=xterm-256color
    fi

    case "''${TMPDIR:-}" in
      */nix-shell.*|*/nix-shell.*/*)
        export ZELLIJ_ORIGINAL_TMPDIR="$TMPDIR"
        tmp_parent="''${TMPDIR%%/nix-shell.*}"
        if [ -n "$tmp_parent" ] && [ -d "$tmp_parent" ]; then
          export TMPDIR="$tmp_parent/"
        elif [ -d /private/tmp ]; then
          export TMPDIR=/private/tmp/
        fi
        ;;
    esac

    zellij_socket_dir="/tmp/zellij-$(${pkgs.coreutils}/bin/id -u)"
    ${pkgs.coreutils}/bin/mkdir -p "$zellij_socket_dir"
    ${pkgs.coreutils}/bin/chmod 700 "$zellij_socket_dir"
    export ZELLIJ_SOCKET_DIR="$zellij_socket_dir"

    ${pkgs.zellij}/bin/zellij "$@"
    status=$?

    if [ "$ghostty_outer_tty" = true ] && ${pkgs.coreutils}/bin/tty -s && old_stty="$(${pkgs.coreutils}/bin/stty -g < /dev/tty 2>/dev/null)"; then
      # Ghostty can answer Zellij's color-scheme query after Zellij exits.
      # Drain that pending DSR response so zsh does not read it as input.
      printf '\033[?2031l' > /dev/tty 2>/dev/null || true
      ${pkgs.coreutils}/bin/sleep 0.05
      ${pkgs.coreutils}/bin/stty -icanon -echo min 0 time 0 < /dev/tty 2>/dev/null || true
      while IFS= read -r -s -n 1 -t 0.02 _ < /dev/tty 2>/dev/null; do
        :
      done
      ${pkgs.coreutils}/bin/stty "$old_stty" < /dev/tty 2>/dev/null || true
    fi

    exit "$status"
  '') // {
    version = pkgs.zellij.version;
  };
in
{
  home.file.".config/zellij/config.kdl" = {
    text = ''
      keybinds clear-defaults=true {
          normal {
              // Keep the default mode quiet; shared bindings below do the work.
          }
          locked {
              bind "Ctrl g" { SwitchToMode "Normal"; }
          }
          resize {
              bind "Ctrl n" { SwitchToMode "Normal"; }
              bind "h" "Left" { Resize "Increase Left"; }
              bind "j" "Down" { Resize "Increase Down"; }
              bind "k" "Up" { Resize "Increase Up"; }
              bind "l" "Right" { Resize "Increase Right"; }
              bind "H" { Resize "Decrease Left"; }
              bind "J" { Resize "Decrease Down"; }
              bind "K" { Resize "Decrease Up"; }
              bind "L" { Resize "Decrease Right"; }
              bind "=" "+" { Resize "Increase"; }
              bind "-" { Resize "Decrease"; }
          }
          pane {
              bind "Ctrl p" { SwitchToMode "Normal"; }
              bind "h" "Left" { MoveFocus "Left"; }
              bind "l" "Right" { MoveFocus "Right"; }
              bind "j" "Down" { MoveFocus "Down"; }
              bind "k" "Up" { MoveFocus "Up"; }
              bind "p" { SwitchFocus; }
              bind "n" { NewPane; SwitchToMode "Normal"; }
              bind "d" { NewPane "Down"; SwitchToMode "Normal"; }
              bind "r" { NewPane "Right"; SwitchToMode "Normal"; }
              bind "s" { NewPane "stacked"; SwitchToMode "Normal"; }
              bind "x" { CloseFocus; SwitchToMode "Normal"; }
              bind "f" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
              bind "z" { TogglePaneFrames; SwitchToMode "Normal"; }
              bind "w" { ToggleFloatingPanes; SwitchToMode "Normal"; }
              bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "Normal"; }
              bind "c" { SwitchToMode "RenamePane"; PaneNameInput 0;}
              bind "i" { TogglePanePinned; SwitchToMode "Normal"; }
          }
          move {
              bind "Ctrl h" { SwitchToMode "Normal"; }
              bind "n" "Tab" { MovePane; }
              bind "p" { MovePaneBackwards; }
              bind "h" "Left" { MovePane "Left"; }
              bind "j" "Down" { MovePane "Down"; }
              bind "k" "Up" { MovePane "Up"; }
              bind "l" "Right" { MovePane "Right"; }
          }
          tab {
              bind "Ctrl t" { SwitchToMode "Normal"; }
              bind "r" { SwitchToMode "RenameTab"; TabNameInput 0; }
              bind "h" "Left" "Up" "k" { GoToPreviousTab; }
              bind "l" "Right" "Down" "j" { GoToNextTab; }
              bind "n" { NewTab; SwitchToMode "Normal"; }
              bind "x" { CloseTab; SwitchToMode "Normal"; }
              bind "s" { ToggleActiveSyncTab; SwitchToMode "Normal"; }
              bind "b" { BreakPane; SwitchToMode "Normal"; }
              bind "]" { BreakPaneRight; SwitchToMode "Normal"; }
              bind "[" { BreakPaneLeft; SwitchToMode "Normal"; }
              bind "1" { GoToTab 1; SwitchToMode "Normal"; }
              bind "2" { GoToTab 2; SwitchToMode "Normal"; }
              bind "3" { GoToTab 3; SwitchToMode "Normal"; }
              bind "4" { GoToTab 4; SwitchToMode "Normal"; }
              bind "5" { GoToTab 5; SwitchToMode "Normal"; }
              bind "6" { GoToTab 6; SwitchToMode "Normal"; }
              bind "7" { GoToTab 7; SwitchToMode "Normal"; }
              bind "8" { GoToTab 8; SwitchToMode "Normal"; }
              bind "9" { GoToTab 9; SwitchToMode "Normal"; }
              bind "Tab" { ToggleTab; }
          }
          scroll {
              bind "Ctrl s" { SwitchToMode "Normal"; }
              bind "e" { EditScrollback; SwitchToMode "Normal"; }
              bind "s" { SwitchToMode "EnterSearch"; SearchInput 0; }
              bind "Ctrl c" { ScrollToBottom; SwitchToMode "Normal"; }
              bind "j" "Down" { ScrollDown; }
              bind "k" "Up" { ScrollUp; }
              bind "Ctrl f" "PageDown" "Right" "l" { PageScrollDown; }
              bind "Ctrl b" "PageUp" "Left" "h" { PageScrollUp; }
              bind "d" { HalfPageScrollDown; }
              bind "u" { HalfPageScrollUp; }
          }
          search {
              bind "Ctrl s" { SwitchToMode "Normal"; }
              bind "Ctrl c" { ScrollToBottom; SwitchToMode "Normal"; }
              bind "j" "Down" { ScrollDown; }
              bind "k" "Up" { ScrollUp; }
              bind "Ctrl f" "PageDown" "Right" "l" { PageScrollDown; }
              bind "Ctrl b" "PageUp" "Left" "h" { PageScrollUp; }
              bind "d" { HalfPageScrollDown; }
              bind "u" { HalfPageScrollUp; }
              bind "n" { Search "down"; }
              bind "p" { Search "up"; }
              bind "c" { SearchToggleOption "CaseSensitivity"; }
              bind "w" { SearchToggleOption "Wrap"; }
              bind "o" { SearchToggleOption "WholeWord"; }
          }
          entersearch {
              bind "Ctrl c" "Esc" { SwitchToMode "Scroll"; }
              bind "Enter" { SwitchToMode "Search"; }
          }
          renametab {
              bind "Ctrl c" { SwitchToMode "Normal"; }
              bind "Esc" { UndoRenameTab; SwitchToMode "Tab"; }
          }
          renamepane {
              bind "Ctrl c" { SwitchToMode "Normal"; }
              bind "Esc" { UndoRenamePane; SwitchToMode "Pane"; }
          }
          session {
              bind "Ctrl o" { SwitchToMode "Normal"; }
              bind "Ctrl s" { SwitchToMode "Scroll"; }
              bind "d" { Detach; }
              bind "w" {
                  LaunchOrFocusPlugin "session-manager" {
                      floating true
                      move_to_focused_tab true
                  };
                  SwitchToMode "Normal"
              }
              bind "c" {
                  LaunchOrFocusPlugin "configuration" {
                      floating true
                      move_to_focused_tab true
                  };
                  SwitchToMode "Normal"
              }
              bind "p" {
                  LaunchOrFocusPlugin "plugin-manager" {
                      floating true
                      move_to_focused_tab true
                  };
                  SwitchToMode "Normal"
              }
              bind "a" {
                  LaunchOrFocusPlugin "zellij:about" {
                      floating true
                      move_to_focused_tab true
                  };
                  SwitchToMode "Normal"
              }
              bind "s" {
                  LaunchOrFocusPlugin "zellij:share" {
                      floating true
                      move_to_focused_tab true
                  };
                  SwitchToMode "Normal"
              }
              bind "l" {
                  LaunchOrFocusPlugin "zellij:layout-manager" {
                      floating true
                      move_to_focused_tab true
                  };
                  SwitchToMode "Normal"
              }
          }
          tmux {
              bind "[" { SwitchToMode "Scroll"; }
              bind "Ctrl b" { Write 2; SwitchToMode "Normal"; }
              bind "\"" { NewPane "Down"; SwitchToMode "Normal"; }
              bind "%" { NewPane "Right"; SwitchToMode "Normal"; }
              bind "z" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
              bind "c" { NewTab; SwitchToMode "Normal"; }
              bind "," { SwitchToMode "RenameTab"; }
              bind "p" { GoToPreviousTab; SwitchToMode "Normal"; }
              bind "n" { GoToNextTab; SwitchToMode "Normal"; }
              bind "Left" { MoveFocus "Left"; SwitchToMode "Normal"; }
              bind "Right" { MoveFocus "Right"; SwitchToMode "Normal"; }
              bind "Down" { MoveFocus "Down"; SwitchToMode "Normal"; }
              bind "Up" { MoveFocus "Up"; SwitchToMode "Normal"; }
              bind "h" { MoveFocus "Left"; SwitchToMode "Normal"; }
              bind "l" { MoveFocus "Right"; SwitchToMode "Normal"; }
              bind "j" { MoveFocus "Down"; SwitchToMode "Normal"; }
              bind "k" { MoveFocus "Up"; SwitchToMode "Normal"; }
              bind "o" { FocusNextPane; }
              bind "d" { Detach; }
              bind "Space" { NextSwapLayout; }
              bind "x" { CloseFocus; SwitchToMode "Normal"; }
          }
          shared_except "locked" {
              bind "Ctrl g" { SwitchToMode "Locked"; }
              bind "Ctrl q" { Quit; }
              bind "Ctrl y" {
                  LaunchOrFocusPlugin "https://github.com/karimould/zellij-forgot/releases/latest/download/zellij_forgot.wasm" {
                      floating true
                      "LOAD_ZELLIJ_BINDINGS" "true"
                  };
              }
              bind "Alt F" { ToggleFloatingPanes; }
              bind "Alt n" { NewPane; }
              bind "Alt N" { NewTab; SwitchToMode "Normal"; }
              bind "Alt i" { MoveTab "Left"; }
              bind "Alt o" { MoveTab "Right"; }
              bind "Alt h" { MoveFocusOrTab "Left"; }
              bind "Alt l" { MoveFocusOrTab "Right"; }
              bind "Alt j" { MoveFocus "Down"; }
              bind "Alt k" { MoveFocus "Up"; }
              bind "Alt =" "Alt +" { Resize "Increase"; }
              bind "Alt -" { Resize "Decrease"; }
              bind "Alt [" { PreviousSwapLayout; }
              bind "Alt ]" { NextSwapLayout; }
              bind "Alt p" { TogglePaneInGroup; }
              bind "Alt Shift p" { ToggleGroupMarking; }
          }
          shared_except "normal" "locked" {
              bind "Enter" "Esc" { SwitchToMode "Normal"; }
          }
          shared_except "pane" "locked" {
              bind "Ctrl p" { SwitchToMode "Pane"; }
          }
          shared_except "resize" "locked" {
              bind "Ctrl n" { SwitchToMode "Resize"; }
          }
          shared_except "scroll" "locked" {
              bind "Ctrl s" { SwitchToMode "Scroll"; }
          }
          shared_except "session" "locked" {
              bind "Ctrl o" { SwitchToMode "Session"; }
          }
          shared_except "tab" "locked" {
              bind "Ctrl t" { SwitchToMode "Tab"; }
          }
          shared_except "move" "locked" {
              bind "Ctrl h" { SwitchToMode "Move"; }
          }
          shared_except "tmux" "locked" {
              bind "Ctrl b" { SwitchToMode "Tmux"; }
          }
      }

      plugins {
          tab-bar location="zellij:tab-bar"
          status-bar location="zellij:status-bar"
          strider location="zellij:strider"
          compact-bar location="zellij:compact-bar"
          session-manager location="zellij:session-manager"
          welcome-screen location="zellij:session-manager" {
              welcome_screen true
          }
          filepicker location="zellij:strider" {
              cwd "/"
          }
          configuration location="zellij:configuration"
          plugin-manager location="zellij:plugin-manager"
          about location="zellij:about"
          autolock location="https://github.com/fresh2dev/zellij-autolock/releases/latest/download/zellij-autolock.wasm" {
              is_enabled true
              triggers "nvim|vim|vi|view|git|fzf|zoxide|atuin|claude|codex"
              reaction_seconds "0.3"
          }
      }

      load_plugins {
          "zellij:link"
          autolock
      }

      theme "default"
      osc8_hyperlinks false
      support_kitty_keyboard_protocol false
    '';
    force = true;
  };

  programs.zellij = {
    enable = true;
    package = zellijNoGhosttyQueries;
  };
}
