{
  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableNushellIntegration = true;
  };

  programs.nushell = {
    enable = true;

    environmentVariables = {
      EDITOR = "hx";
      VISUAL = "hx";
    };

    extraConfig = ''
      # Enter a named development shell from ~/nix-config without forcing
      # Nushell from the flake's shell hook.
      def ndev [shell: string = "rust"] {
        nix develop $"($env.HOME)/nix-config#($shell)" --command nu
      }

      # Explicitly attach to or create a Zellij session.
      def zj [session: string = "main"] {
        zellij attach --create $session
      }
    '';
  };
}
