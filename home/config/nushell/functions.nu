# Enter a named development shell from ~/nix-config without forcing
# Nushell from the flake's shell hook.
def ndev [shell: string = "rust"] {
  nix develop $"($env.HOME)/nix-config#($shell)" --command nu
}

# Explicitly attach to or create a Zellij session.
def zj [session: string = "main"] {
  zellij attach --create $session
}

# Interactively choose a bookmark and start a new change on top of it.
def jjn [] {
  let bookmark = jj bookmark list --all --template 'name ++ if(remote, "@" ++ remote, "") ++ "\n"' | fzf | str trim
  if ($bookmark | is-not-empty) {
    jj new $bookmark
  }
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

# Copy files or directories to the Windows file clipboard for Explorer paste.
def file-copy [...paths: path] {
  if ($paths | is-empty) {
    error make { msg: "file-copy: specify at least one path" }
  }

  let windows_paths = $paths | each { |path|
    let expanded = $path | path expand
    if not ($expanded | path exists) {
      error make { msg: $"file-copy: path does not exist: ($path)" }
    }

    let conversion = do { ^wslpath -w $expanded } | complete
    if $conversion.exit_code != 0 {
      let detail = $conversion.stderr | str trim
      error make { msg: $"file-copy: failed to convert path: ($path): ($detail)" }
    }

    $conversion.stdout | str trim
  }

  let powershell = which powershell.exe
  if ($powershell | is-empty) {
    error make { msg: "file-copy: powershell.exe was not found in PATH" }
  }

  # Pass paths as UTF-8 JSON instead of interpolating them into PowerShell code.
  # /init is WSL's Windows-executable handler and also works when binfmt is absent.
  let powershell_path = $powershell | get path | first
  let result = $windows_paths
    | to json --raw
    | ^/init $powershell_path -NoLogo -NoProfile -NonInteractive -Command '[Console]::InputEncoding = [Text.UTF8Encoding]::new($false); $json = [Console]::In.ReadToEnd(); $paths = ConvertFrom-Json $json; Set-Clipboard -LiteralPath $paths'
    | complete

  if $result.exit_code != 0 {
    let detail = $result.stderr | str trim
    error make { msg: $"file-copy: failed to set the Windows file clipboard: ($detail)" }
  }
}

# Open an image in a WSLg window. imv also supports SVG.
def img [file: path] {
  ^imv ($file | path expand)
}
