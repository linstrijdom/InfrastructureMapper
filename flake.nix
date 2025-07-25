{
  description = "NixOS developer environment for QGIS plugins.";

  inputs.geospatial.url = "github:imincik/geospatial-nix.repo";
  inputs.nixpkgs.follows = "geospatial/nixpkgs";

  outputs =
    {
      self,
      geospatial,
      nixpkgs,
    }:
    let
      system = "x86_64-linux";
      profileName = "InfrastructureMapper";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
      extraPythonPackages = ps: [
        ps.pyqtwebengine
        ps.jsonschema
        ps.debugpy
        ps.future
        ps.psutil
      ];
      qgisWithExtras = geospatial.packages.${system}.qgis.override {
        inherit extraPythonPackages;
      };
      qgisLtrWithExtras = geospatial.packages.${system}.qgis-ltr.override {
        inherit extraPythonPackages;
      };
      postgresWithPostGIS = pkgs.postgresql.withPackages (ps: [ ps.postgis ]);
    in
    {
      packages.${system} = {
        default = qgisWithExtras;
        qgis-ltr = qgisLtrWithExtras;
        postgres = postgresWithPostGIS;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.chafa
          pkgs.ffmpeg
          pkgs.gdb
          pkgs.git
          pkgs.glow # terminal markdown viewer
          pkgs.gource # Software version control visualization
          pkgs.gum
          pkgs.gum # UX for TUIs
          pkgs.jq
          pkgs.libsForQt5.kcachegrind
          pkgs.nixfmt-rfc-style
          pkgs.pre-commit
          pkgs.pyprof2calltree # needed to covert cprofile call trees into a format kcachegrind can read
          pkgs.python3
          pkgs.qgis
          pkgs.qt5.full # so we get designer
          pkgs.qt5.qtbase
          pkgs.qt5.qtlocation
          pkgs.qt5.qtquickcontrols2
          pkgs.qt5.qtsvg
          pkgs.qt5.qttools
          pkgs.skate # Distributed key/value store
          pkgs.vim
          pkgs.virtualenv
          pkgs.vscode
          pkgs.sqlfluff
          pkgs.marp-cli
          pkgs.shellcheck
          pkgs.shfmt
          pkgs.markdownlint-cli
          pkgs.yamllint
          pkgs.yamlfmt
          pkgs.actionlint # for checking gh actions
          postgresWithPostGIS
          pkgs.nodePackages.cspell
          (pkgs.python3.withPackages (ps: [
            ps.python
            ps.pip
            ps.setuptools
            ps.wheel
            ps.pytest
            ps.pytest-qt
            ps.black
            ps.click # needed by black
            ps.jsonschema
            ps.pandas
            ps.odfpy
            ps.psutil
            ps.httpx
            ps.toml
            ps.typer
            ps.paver
            # For autocompletion in vscode
            ps.pyqt5-stubs
            ps.debugpy
            ps.numpy
            ps.gdal
            ps.toml
            ps.typer
            ps.snakeviz # For visualising cprofiler outputs
            # Add these for SQL linting/formatting:
            ps.sqlfmt
          ]))
        ];
        shellHook = ''
          export PGHOST="$PWD/pgdata"
          export PGPORT=5432

          if [ ! -d ".venv" ]; then
            python -m venv .venv
          fi

          # Activate the virtual environment
          source .venv/bin/activate

          # Upgrade pip and install packages from requirements.txt if it exists
          pip install --upgrade pip > /dev/null
          if [ -f requirements.txt ]; then
            echo "Installing Python requirements from requirements.txt..."
            pip install -r requirements.txt
          else
            echo "No requirements.txt found, skipping pip install."
          fi

          echo "-----------------------"
          echo "🌈 Your Dev Environment is prepared."
          echo "To run QGIS with your profile, use one of these commands:"
          echo ""
          echo "  nix run .#qgis"
          echo "  nix run .#qgis-ltr"
          echo ""
          echo "📒 Note:"
          echo "-----------------------"
          echo "We provide a ready-to-use"
          echo "VSCode environment which you"
          echo "can start like this:"
          echo ""
          echo "./vscode.sh"
          echo "-----------------------"
          echo "Postgres should be running with its"
          echo "data stored in ./pgdata"
          echo "You need to stop it manually with this command"
          echo "${postgresWithPostGIS}/bin/pg_ctl -D ./pgdata stop -m fast"
          echo ""
          echo "Or use ./stop_pg.sh to stop it"
        '';
      };

      apps.${system} = {
        qgis = {
          type = "app";
          program = "${qgisWithExtras}/bin/qgis";
          args = [
            "--profile"
            "${profileName}"
          ];
        };
        qgis-ltr = {
          type = "app";
          program = "${qgisLtrWithExtras}/bin/qgis";
          args = [
            "--profile"
            "${profileName}"
          ];
        };
      };
    };
}
