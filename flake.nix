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
            settings.global.excludes = [
              "_sources/**"
            ];
            settings.formatter = {
              # keep-sorted start block=yes
              rumdl = {
                command = "${pkgs.lib.getExe pkgs.rumdl}";
                options = [
                  "fmt"
                  "--config"
                  (builtins.toString ./.rumdl.toml)
                ];
                includes = [ "*.md" ];
              };
              tombi = {
                command = "${pkgs.lib.getExe pkgs.tombi}";
                options = [
                  "format"
                  "--offline"
                ];
                includes = [ "*.toml" ];
              };
              # keep-sorted end
            };
            programs = {
              # keep-sorted start block=yes
              keep-sorted.enable = true;
              nixfmt.enable = true;
              oxfmt = {
                enable = true;
                includes = [ "*.json" ];
              };
              stylua = {
                enable = true;
                settings = pkgs.lib.pipe ./stylua.toml [
                  builtins.readFile
                  builtins.fromTOML
                ];
              };
              toml-sort.enable = true;
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

        sources = pkgs.callPackage ./_sources/generated.nix { };
        nvim-treesitter-raw = pkgs.stdenvNoCC.mkDerivation {
          inherit (sources.nvim-treesitter) pname version src;
          doBuild = false;
          buildPhase = ":";
          installPhase = ''
            runHook preInstall
            mkdir -p $out
            cp -r . $out/
            runHook postInstall
          '';
          meta = {
            platforms = pkgs.lib.platforms.all;
          };
        };
        nvim-treesitter = (
          pkgs.symlinkJoin {
            name = "nvim-treesitter";
            paths = [
              nvim-treesitter-raw
            ]
            ++ pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
          }
        );
        mkInitVim =
          extraConfig:
          pkgs.writeTextFile {
            name = "init-vim";
            destination = "/init.vim";
            text = ''
              set runtimepath+=${nvim-treesitter}
              ${extraConfig}
            '';
          };
        customInitVim = mkInitVim "";
        wrappedVusted = pkgs.symlinkJoin {
          name = "vusted-custom";
          paths = [ pkgs.lua51Packages.vusted ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/vusted \
              --set VUSTED_ARGS "--headless --clean -u ${customInitVim}/init.vim"
          '';
        };
        luacov = pkgs.lua51Packages.luacov;
        luacov-reporter-lcov = pkgs.fetchFromGitHub {
          owner = "daurnimator";
          repo = "luacov-reporter-lcov";
          rev = "4d881ddb4eeec5ac0cd7d4b7679e3e59f9ac5745";
          hash = "sha256-o+9E+pMVpWpd4M0gBnU0g9OA7UZjNbuqFa6WG2j73nE=";
        };
        customInitVimWithCoverage =
          let
            luacovPath = "${luacov}/share/lua/5.1";
            lcovReporterPath = "${luacov-reporter-lcov}";
          in
          mkInitVim "lua package.path = '${luacovPath}/?.lua;${luacovPath}/?/init.lua;${lcovReporterPath}/?.lua;${lcovReporterPath}/?/init.lua;' .. package.path";
        wrappedVustedWithCoverage = pkgs.symlinkJoin {
          name = "vusted-coverage";
          paths = [ pkgs.lua51Packages.vusted ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/vusted \
              --set VUSTED_ARGS "--headless --clean -u ${customInitVimWithCoverage}/init.vim"
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
          nvfetcher = [
            pkgs.nvfetcher
          ];
          renovate = [
            pkgs.renovate
          ];
          # keep-sorted end
          default = actions ++ renovate ++ neovim ++ nvfetcher ++ [ treefmt.config.build.wrapper ];
        };
      in
      {
        formatter = treefmt.config.build.wrapper;
        checks = {
          formatting = treefmt.config.build.check self;
        };
        apps = {
          check-actions = runAs "check-actions" devPackages.actions ''
            actionlint
            ghalint run
            zizmor .github/workflows .github/actions
          '';
          check-renovate-config = runAs "check-renovate-config" devPackages.renovate ''
            renovate-config-validator --strict
          '';
          test = runAs "vusted-test" devPackages.neovim ''
            vusted test
          '';
          coverage =
            runAs "vusted-coverage"
              [
                wrappedVustedWithCoverage
                pkgs.neovim
                luacov
                pkgs.gnused
              ]
              ''
                vusted test --coverage
                export LUA_PATH="${luacov-reporter-lcov}/?.lua;${luacov-reporter-lcov}/?/init.lua;;"
                luacov -r lcov
                sed -i "s|SF:$PWD/|SF:|g" luacov.report.out
              '';
          update-nvim-treesitter = runAs "update-nvim-treesitter" devPackages.nvfetcher ''
            nvfetcher
          '';

        };
        devShells = pkgs.lib.attrsets.mapAttrs (
          name: buildInputs: pkgs.mkShell { inherit buildInputs; }
        ) devPackages;
      }
    );
}
