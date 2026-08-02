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
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixos-wsl,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      rustShell = import ./devshells/rust.nix { inherit pkgs; };
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
              users.dnc = import ./home;
            };
          }
        ];
      };

      homeConfigurations.dnc = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home ];
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
              for program in nu carapace zoxide hx zellij jj git just direnv rg fd difft adb fastboot sccache; do
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
