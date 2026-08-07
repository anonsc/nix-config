let
  functions = ./config/nushell/functions.nu;
  pinguLicense = ./config/nushell/pingu-LICENSE.txt;
  welcome = ./config/nushell/welcome.nu;
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
    extraConfig = ''
      $env.config.show_banner = false
      source ${functions}
      source ${welcome}
    '';
  };

  xdg.configFile."nushell/functions.nu".source = functions;
  xdg.configFile."nushell/pingu-LICENSE.txt".source = pinguLicense;
  xdg.configFile."nushell/welcome.nu".source = welcome;
}
