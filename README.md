# NixOS-WSL development environment

NixOS-WSL 上の個人用開発環境を、NixOS と Home Manager の単一 Flake として管理する構成です。既定ユーザーは `dnc`、対話シェルは Nushell です。共通 CLI、Docker Engine、常駐 sccache、Linux ネイティブ用 Rust devShell を含みます。

設定リポジトリは `/home/dnc/nix-config` に置く前提です。プロジェクトのソースも `/mnt/c` などの Windows マウントではなく、WSL の Linux ファイルシステム内に置いてください。

## 構成

```text
.
├── flake.nix                    # inputs、NixOS/Home/開発シェル/checks
├── flake.lock                   # 依存リビジョンの固定
├── hosts/wsl/default.nix        # NixOS-WSL ホストと dnc ユーザー
├── home/                        # Home Manager モジュールと共有 identity
│   └── config/                 # アプリ本来の形式で編集する設定ファイル
│       ├── helix/config.toml
│       ├── helix/languages.toml
│       ├── jj/10-ui.toml
│       ├── nushell/functions.nu
│       └── zellij/config.kdl
├── modules/docker.nix           # rootful Docker Engine と Compose v2
├── modules/nix-settings.nix     # Flake、GC、store 最適化
├── modules/services/sccache.nix # systemd ユーザーサービス
├── devshells/rust.nix           # Rust、sccache、mold、clang
├── scripts/check-rust.sh        # Rust devShell のスモークテスト
├── windows/install-hackgen35-nf.ps1
└── justfile
```

秘密情報、API キー、個人トークンはこの Flake に追加しないでください。

アプリ固有の設定は、編集しやすいよう `home/config` 以下へネイティブ形式のまま置き、Home Manager の `xdg.configFile` で `~/.config` 以下へ配置します。パッケージの有効化、シェル統合、Git と Jujutsu で共有する identity など、複数の設定を合成する必要がある部分だけを Nix で生成します。配置先は Nix store への読み取り専用リンクになるため、実環境の `~/.config` ではなく、このリポジトリのソースを編集して再構築してください。

## 初回導入

### 1. NixOS-WSL を用意する

Windows 側で WSL 2 を有効化し、[NixOS-WSL の最新リリース](https://github.com/nix-community/NixOS-WSL/releases/latest)から `nixos.wsl` を導入します。以下ではディストリビューション名を `NixOS` とします。別名で登録した場合は読み替えてください。

最初の NixOS-WSL セッションではまだ `dnc` が存在しないため、一時ディレクトリから初回適用します。`<repository-url>` はこのリポジトリの URL に置き換えます。

```bash
nix-shell -p git --run 'git clone https://github.com/anonsc/nix-config.git /tmp/nix-config-bootstrap'
cd /tmp/nix-config-bootstrap
sudo nixos-rebuild build --flake .#wsl
sudo nixos-rebuild switch --flake .#wsl
exit
```

初回の `switch` では、作成直後の `dnc` に対する user systemd/DBus がまだ起動していないため、`Unable to autolaunch a dbus-daemon without a $DISPLAY` や `getty@tty1.service` を伴って終了コード 4 になる場合があります。DBus の未導入や X11 の問題ではないため、`DISPLAY` の設定や `dbus-daemon` の手動起動は行わず、そのまま次の WSL 再起動へ進んでください。

初期状態では `nix-command` と `flakes` がまだ無効な場合があるため、Gitの取得には従来形式の `nix-shell` を使っています。新しい `nix shell` を使う場合は、`nix --extra-experimental-features 'nix-command flakes' shell ...` のように機能を一時的に有効化してください。

Windows の PowerShell から一度停止して再起動します。

```powershell
wsl --terminate NixOS
wsl -d NixOS
```

新しいセッションのユーザーが `dnc` であることを確認し、標準位置へ clone します。

```nu
whoami
systemctl --user is-active dbus.service
git clone <repository-url> ~/nix-config
cd ~/nix-config
just check
just switch
```

`whoami` の期待値は `dnc`、DBus の期待値は `active` です。再起動後の `just switch` で初回適用を完了します。以後の NixOS 再構築では、統合された Home Manager 設定も同時に適用されます。

### 2. 日常の更新と適用

安全な基本フローは「lock 更新 → check → build → switch」です。`flake.lock` の差分を確認してから適用してください。

```nu
cd ~/nix-config
just update
jj diff -- flake.lock
just check
just build
just switch
```

入力を更新しない通常の変更では `just update` を省略します。`just preflight` は `check` と `build` を順に実行します。全レシピと説明は次で確認できます。

```nu
just --list
```

Home Manager だけを再適用する場合は次を使えます。ただし、既定シェル、Docker、Nix GC などのシステム設定は変更されません。通常は `just switch` を推奨します。

```nu
just home-switch
```

Home Managerは初回NixOS適用時のsystemdユーザーmanagerとの競合を避けるため、ユーザーサービスを適用処理内では即時起動しません。sccacheの定義を変更してHome Managerだけを適用した場合は、続けて `systemctl --user daemon-reload` と `systemctl --user restart sccache` を実行してください。通常の初回導入では、後述のWSL再起動時に自動起動します。

### 3. ロールバック

NixOS と統合 Home Manager を直前の generation へ戻すには次を実行します。

```nu
sudo nixos-rebuild list-generations
sudo nixos-rebuild switch --rollback
```

Home Manager を単独適用した場合は、`home-manager generations` で世代を確認し、戻したい `/nix/store/...-home-manager-generation/activate` を実行できます。

この構成では Nix GC が毎週実行され、30 日より古い generation と、そこから参照されない store path が削除対象になります。ディスク使用量を抑える一方、削除済み世代へはロールバックできません。保持期間は [`modules/nix-settings.nix`](modules/nix-settings.nix) の `--delete-older-than 30d` で調整します。

## Rust devShell

非対話コマンドは Nushell を強制起動せず、そのまま実行できます。

```nu
nix develop ~/nix-config#rust --command cargo --version
```

対話環境へ入る場合は次のいずれかを使います。

```nu
nix develop ~/nix-config#rust --command nu
ndev rust
```

Rust devShell は `rustc`、`cargo`、`rust-analyzer`、`rustfmt`、`clippy`、`cargo-make`、`sccache`、`mold`、`clang`、`pkg-config` を提供します。`RUSTC_WRAPPER` は sccache を指し、`x86_64-unknown-linux-gnu` ターゲットだけに clang と mold を設定します。mold は OS 全体へ適用されません。Android、musl、組み込みなどでは、用途別 devShell を追加してこのネイティブ向け設定を継承しない構成にできます。

非対話動作、sccache、mold、最小 Rust プロジェクトのビルドはまとめて検査できます。

```nu
just rust-check
```

### 既存リポジトリで direnv を使う

チームリポジトリのルートに、ローカル専用の `.envrc` を次の内容で作ります。`.envrc` は direnv が解釈する Bash 形式であり、対話シェルを Bash に変更するものではありません。

```bash
watch_file "$HOME/nix-config/flake.nix"
watch_file "$HOME/nix-config/flake.lock"
watch_file "$HOME/nix-config/devshells/rust.nix"

use flake "$HOME/nix-config#rust"
```

リポジトリへ誤って追加しないよう、ローカル除外を設定します。

```text
# .git/info/exclude
.envrc
.direnv/
```

対象ディレクトリで一度だけ許可します。

```nu
direnv allow
$env.RUSTC_WRAPPER
```

期待値は Nix store 内の `.../bin/sccache` です。Nushell の direnv フックが現在のシェルへ環境を反映するため、Zellij の新しいペインでも同じディレクトリへ移動すれば環境が復元されます。将来そのリポジトリが正式な Flake を持った場合は、`.envrc` を `use flake` に変更できます。

## sccache

sccache は `dnc` の systemd ユーザーサービスとしてフォアグラウンド起動し、複数リポジトリでキャッシュを共有します。ユーザーには linger を設定しているため、ユーザー manager は WSL の起動中に維持されます。

適用後の確認コマンドは次のとおりです。

```nu
systemctl --user is-enabled sccache
systemctl --user status sccache --no-pager
systemctl --user show sccache --property Environment
sccache --show-stats
loginctl show-user dnc --property Linger
```

期待結果は以下です。

- `sccache.service` が `enabled` かつ `active (running)`
- `SCCACHE_NO_DAEMON=1` と `SCCACHE_IDLE_TIMEOUT=0`
- キャッシュ先が `/home/dnc/.cache/sccache`
- 最大サイズが `20 GiB`
- `Linger=yes`

サービス起動前にクライアントが別の sccache server を自動起動してしまった場合は、`sccache --stop-server` の後に `systemctl --user restart sccache` を実行します。

## Docker

Docker Desktop ではなく、NixOS-WSL 内の rootful Docker Engine を systemd サービスとして使用します。適用後、一度 WSL を終了して再度ログインし、グループ所属と Engine を確認します。

```nu
id --groups --name
systemctl is-active docker
docker info
docker compose version
docker run --rm hello-world
```

期待結果は、グループ一覧に `docker` が含まれ、サービスが `active`、`docker info` が sudo なしで成功し、`docker compose version` が Compose v2 を表示することです。

> [!WARNING]
> `docker` グループのメンバーは、コンテナのマウントや privileged 実行を通じて実質的に root 相当の権限を持ちます。信頼できないイメージや Compose 定義を安易に実行しないでください。

## Nushell と共通ツール

対話シェルと主要 CLI は次で確認できます。Bash スクリプトは `bash ./script.sh` のように明示して実行します。

```nu
getent passwd dnc
bash -c 'for cmd in nu hx jj git just zellij carapace fzf zoxide direnv rg fd difft adb fastboot sccache bat btm dust jq nixd nixfmt taplo marksman vscode-json-language-server nix-locate ,; do command -v "$cmd"; done'
jj config get ui.editor
jj config get ui.diff-formatter
jj config get user.email
git config --global --get user.email
hx --health nix
hx --health toml
hx --health markdown
hx --health json
help ndev
help zj
direnv status
```

期待値は、`dnc` のシェルが Nix store 内の `nu`、Jujutsu の editor が `hx`、diff formatter が `difft` であることです。Helix の health では Nix に `nixd`、TOML に `taplo`、Markdown に `marksman`、JSON に `vscode-json-language-server` が表示されます。Carapace 補完は `git ` などを入力して Tab を押して対話確認します。zoxide、Carapace、fzf、direnv のフックは Home Manager が生成する Nushell 設定へ自動的に読み込まれます。ファイルを対話的に検索する場合は、検索起点へ移動して `fzf` を実行します。隠しファイルも `fd` から候補へ渡されるため、ホーム全体なら `cd ~` のあと `fzf` を起動し、ファイル名の一部を入力して絞り込めます。

一時的に試したいコマンドは、恒久パッケージへ追加する前に comma で実行できます。Nushell では外部コマンドであることを `^` で明示します。

```nu
^, cowsay hello
nix-locate bin/cowsay
```

Zellij は自動起動しません。明示的に session を attach/create します。

```nu
zj main
```

Android ツールは次で確認できます。ネットワーク ADB は WSL 内から利用できますが、USB 端末接続用の `usbipd-win` はこの構成の対象外です。

```nu
adb version
fastboot --version
```

## HackGen35 NF

フォントは Windows Terminal が描画するため、WSL 側には導入しません。必要な場合だけ、Windows PowerShell から独立スクリプトを実行します。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "\\wsl.localhost\NixOS\home\dnc\nix-config\windows\install-hackgen35-nf.ps1"
```

スクリプトは HackGen の最新公式リリースから HackGen35 NF を現在の Windows ユーザーへインストールします。Windows Terminal の設定は変更しません。Terminal を再起動した後、対象プロファイルのフォントとして `HackGen35 Console NF` を手動選択してください。

## 実環境での最終確認

このリポジトリ自体では Flake 評価とビルドを自動化しています。次は適用済み NixOS-WSL でのみ確認できます。

1. Windows から `wsl -d NixOS -- whoami` を実行し、`dnc` が返る。
2. Nushell の対話セッションで Carapace の Tab 補完、zoxide、direnv の自動反映を確認する。
3. `systemctl --user status sccache` と `sccache --show-stats` で常駐サービス、20 GiB、保存先を確認する。
4. sudo なしの `docker info`、`docker compose version`、テストコンテナを確認する。
5. 外部 `.envrc` を `direnv allow` し、同じ Nushell 内と新しい Zellij ペインの両方で `$env.RUSTC_WRAPPER` を確認する。
6. 必要なら Windows 側へフォントを入れ、Windows Terminal で描画を確認する。

`just check`、`just build`、`just rust-check` が成功しても、systemd と Docker daemon の実稼働、Windows の既定 WSL ユーザー、対話補完はこの手順で別途確認してください。
