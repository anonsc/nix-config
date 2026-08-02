{
  programs.jujutsu = {
    enable = true;
    settings.ui = {
      editor = "hx";
      diff-formatter = [
        "difft"
        "--color=always"
        "$left"
        "$right"
      ];
    };
  };
}
