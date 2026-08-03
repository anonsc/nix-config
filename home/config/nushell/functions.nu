# Enter a named development shell from ~/nix-config without forcing
# Nushell from the flake's shell hook.
def ndev [shell: string = "rust"] {
  nix develop $"($env.HOME)/nix-config#($shell)" --command nu
}

# Explicitly attach to or create a Zellij session.
def zj [session: string = "main"] {
  zellij attach --create $session
}

def --wrapped adb [...args: string] {
  let adb = $env.WINDOWS_ADB
  ^$adb ...$args
}

# Copy piped text to the WSLg system clipboard shared with Windows.
def clip-copy [] {
  $in | to text | ^wl-copy
}

# Read text from the WSLg system clipboard without adding a newline.
def clip-paste [] {
  ^wl-paste --no-newline
}

# Open an image in a WSLg window. imv also supports SVG.
def img [file: path] {
  ^imv ($file | path expand)
}
