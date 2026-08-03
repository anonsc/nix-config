{
  description = "Reproducible NixOS-WSL development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixos-wsl,
      home-manager,
      nix-index-database,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      rustShell = import ./devshells/rust.nix { inherit pkgs; };
      homeModule = {
        imports = [
          nix-index-database.homeModules.default
          ./home
        ];
        programs.nix-index.package = nix-index-database.packages.${system}.nix-index-with-small-db;
        programs.nix-index-database.comma.enable = true;
      };
    in
    {
      nixosConfigurations.wsl = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          nixos-wsl.nixosModules.default
          home-manager.nixosModules.home-manager
          ./hosts/wsl
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-backup";
              users.dnc = homeModule;
            };
          }
        ];
      };

      homeConfigurations.dnc = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ homeModule ];
      };

      devShells.${system} = {
        default = rustShell;
        rust = rustShell;
      };

      formatter.${system} = pkgs.nixfmt-tree;

      checks.${system} = {
        nixos-wsl = self.nixosConfigurations.wsl.config.system.build.toplevel;
        home-dnc = self.homeConfigurations.dnc.activationPackage;
        rust-shell = self.devShells.${system}.rust;

        home-cli =
          pkgs.runCommand "home-cli-check"
            {
              nativeBuildInputs = [ self.homeConfigurations.dnc.config.home.path ];
            }
            ''
              for program in nu carapace fzf zoxide hx zellij jj git just direnv rg fd difft adb fastboot sccache bat btm dust jq nixd nixfmt taplo marksman vscode-json-language-server nix-locate ,; do
                command -v "$program" >/dev/null
              done
              touch "$out"
            '';

        nushell-config =
          pkgs.runCommand "nushell-config-check"
            {
              nativeBuildInputs = [ self.homeConfigurations.dnc.config.home.path ];
            }
            ''
              nu \
                --config ${self.homeConfigurations.dnc.activationPackage}/home-files/.config/nushell/config.nu \
                --commands 'help ndev | ignore; help zj | ignore'
              touch "$out"
            '';

        docker-compose =
          pkgs.runCommand "docker-compose-check"
            {
              nativeBuildInputs = [ self.nixosConfigurations.wsl.config.system.path ];
            }
            ''
              docker compose version
              touch "$out"
            '';
      };
    };
}
