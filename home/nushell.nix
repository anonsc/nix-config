let
  functions = ./config/nushell/functions.nu;
in
{
  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableNushellIntegration = true;
    defaultCommand = "fd --hidden --type f --exclude .git";
    fileWidget.command = "fd --hidden --type f --exclude .git";
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

    extraConfig = "source ${functions}";
  };

  xdg.configFile."nushell/functions.nu".source = functions;
}
