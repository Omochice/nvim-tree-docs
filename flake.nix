{
  description = "Highly configurable documentation generator using treesitter";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur-packages = {
      url = "github:Omochice/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      flake-utils,
      nur-packages,
      neovim-nightly-overlay,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            nur-packages.overlays.default
            neovim-nightly-overlay.overlays.default
          ];
        };
        treefmt = treefmt-nix.lib.evalModule pkgs (
          { ... }:
          {
            settings.global.excludes = [ ];
            programs = {
              # keep-sorted start block=yes
              fish_indent.enable = true;
              formatjson5 = {
                enable = true;
                indent = 2;
              };
              keep-sorted.enable = true;
              mdformat.enable = true;
              nixfmt.enable = true;
              shfmt.enable = true;
              stylua = {
                enable = true;
                settings = ./stylua.toml |> builtins.readFile |> builtins.fromTOML;
              };
              yamlfmt = {
                enable = true;
                settings = {
                  formatter = {
                    type = "basic";
                    retain_line_breaks_single = true;
                  };
                };
              };
              # keep-sorted end
            };
          }
        );
        runAs =
          name: runtimeInputs: text:
          let
            program = pkgs.writeShellApplication {
              inherit name runtimeInputs text;
            };
          in
          {
            type = "app";
            program = "${program}/bin/${name}";
          };
        nvim-treesitter = (
          pkgs.symlinkJoin {
            name = "nvim-treesitter";
            paths = [
              pkgs.vimPlugins.nvim-treesitter
            ]
            ++ pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
          }
        );
        customInitVim = pkgs.stdenvNoCC.mkDerivation {
          name = "init-vim";
          src = ./.;
          buildCommand =
            let
              init-vim = ''
                set runtimepath+=${nvim-treesitter}
              '';
            in
            ''
              mkdir -p $out
              echo "${init-vim}" > $out/init.vim
            '';
        };
        wrappedVusted = pkgs.symlinkJoin {
          name = "vusted-custom";
          paths = [ pkgs.lua51Packages.vusted ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/vusted \
              --set VUSTED_ARGS "--headless --clean -u ${customInitVim}/init.vim"
          '';
        };
        devPackages = rec {
          # keep-sorted start block=yes
          actions = [
            pkgs.actionlint
            pkgs.ghalint
            pkgs.zizmor
          ];
          neovim = [
            pkgs.neovim
            # pkgs.lua51Packages.luarocks-nix
            wrappedVusted
          ];
          renovate = [
            pkgs.renovate
          ];
          # keep-sorted end
          default = actions ++ renovate ++ neovim ++ [ treefmt.config.build.wrapper ];
        };
      in
      {
        formatter = treefmt.config.build.wrapper;
        checks = {
          formatting = treefmt.config.build.check self;
        };
        apps = {
          check-actions =
            ''
              actionlint
              ghalint run
              zizmor .github/workflows .github/actions
            ''
            |> runAs "check-actions" devPackages.actions;
          check-renovate-config =
            ''
              renovate-config-validator --strict renovate.json5
            ''
            |> runAs "check-renovate-config" devPackages.renovate;
          test =
            ''
              vusted test
            ''
            |> runAs "vusted-test" devPackages.neovim;
        };
        devShells =
          devPackages
          |> pkgs.lib.attrsets.mapAttrs (name: buildInputs: pkgs.mkShell { inherit buildInputs; });
      }
    );
}
