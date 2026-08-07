# Pingu pixel art adapted from sheepla/pingu (MIT).
# https://github.com/sheepla/pingu
# See pingu-LICENSE.txt.

# Keep non-interactive commands and scripts silent.
if $nu.is-interactive {
  let pingu = [
    ' ...        .     ...   ..    ..     .........'
    ' ...     ....          ..  ..      ... .....  .. ..'
    ' ...    .......      ...         ... . ..... BBBBBBB'
    '.....  ........ .BBBBBBBBBBBBBBB.....  ... BBBBBBBBBB.  .'
    ' .... ........BBBBBBBBBBBBBBBBBBBBB.  ... BBBBBBBBBBB'
    '      ....... BBWWWWBBBBBBBBBBBBBBBB.... BBBBBBBBBBBB'
    '.    .  .... BBWWBBWWBBBBBBBBBBWWWWBB... BBBBBBBBBBB'
    '   ..   ....BBBBWWWWBBRRRRRRBBWWBBWWB.. .BBBBBBBBBBB'
    '    .       BBBBBBBBRRRRRRRRRRBWWWWBB.   .BBBBBBBBBB'
    '   ....     .BBBBBBBBRRRRRRRRBBBBBBBB.      BBBBBBBB'
    '  .....      .  BBBBBBBBBBBBBBBBBBBB.        BBBBBBB.'
    '......     .. . BBBBBBBBBBBBBBBBBB . .      .BBBBBBB'
    '......       BBBBBBBBBBBBBBBBBBBBB  .      .BBBBBBB'
    '......   .BBBBBBBBBBBBBBBBBBYYWWBBBBB  ..  BBBBBBB'
    '...    . BBBBBBBBBBBBBBBBYWWWWWWWWWBBBBBBBBBBBBBB.'
    '       BBBBBBBBBBBBBBBBYWWWWWWWWWWWWWBBBBBBBBB .'
    '      BBBBBBBBBBBBBBBYWWWWWWWWWWWWWWWWBB    .'
    '     BBBBBBBBBBBBBBBYWWWWWWWWWWWWWWWWWWW  ........'
    '  .BBBBBBBBBBBBBBBBYWWWWWWWWWWWWWWWWWWWW    .........'
    ' .BBBBBBBBBBBBBBBBYWWWWWWWWWWWWWWWWWWWWWW       .... . .'
  ]

  let rendered_pingu = $pingu
    | each { |line|
        $line
        | str replace --all 'R' $"(ansi light_red_bold)#(ansi reset)"
        | str replace --all 'Y' $"(ansi light_yellow_bold)#(ansi reset)"
        | str replace --all 'B' $"(ansi dark_gray_bold)#(ansi reset)"
        | str replace --all 'W' $"(ansi white_bold)#(ansi reset)"
      }
    | str join "\n"

  let now = date now | format date "%Y-%m-%d %H:%M"
  print $rendered_pingu
  print $"(ansi light_yellow_bold)NOOT NOOT(ansi reset)  ($now)  startup: ($nu.startup-time)"
}
