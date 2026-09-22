{ pkgs, lib, ... }:

{
  home.activation.installClaudeCode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -x "$HOME/.local/bin/claude" ]; then
      export PATH="${pkgs.curl}/bin:${pkgs.coreutils}/bin:${pkgs.perl}/bin:${pkgs.jq}/bin:${pkgs.zstd}/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
      $DRY_RUN_CMD ${pkgs.curl}/bin/curl -fsSL https://claude.ai/install.sh | $DRY_RUN_CMD ${pkgs.bash}/bin/bash
    fi
  '';
}
