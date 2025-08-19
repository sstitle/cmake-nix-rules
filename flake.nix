{
  description = "Nix rules for generating CMake expressions";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Import our cmake-nix-rules implementation
        cmake-rules = import ./nix { inherit pkgs; };
        
        # Discover modules from examples directory
        moduleDiscovery = cmake-rules.discoverModules ./examples;
        
        # Resolve module dependencies and build in proper order
        modules = cmake-rules.resolveModuleDependencies moduleDiscovery pkgs cmake-rules;
        
        # Global build configuration
        buildConfig = import ./examples/build-config.nix { inherit pkgs; };
        
      in {
        # Export the rules for other flakes to use
        lib = cmake-rules;
        
        # Development shell for working on this project
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            cmake
            ninja
            gcc
            clang
            gdb
            pkg-config
            eigen
            spdlog
          ];
        };

        # Individual module packages
        packages = modules // {
          # Default: build all modules
          default = pkgs.symlinkJoin {
            name = "cmake-nix-rules-examples";
            paths = builtins.attrValues modules;
          };
          
          # Test runner
          tests = (import ./tests { inherit pkgs; }).runAllTests;
        };

        # Apps for development workflow
        apps = {
          # Test all modules
          test-all = {
            type = "app";
            program = "${pkgs.writeShellScript "test-all" ''
              set -e
              echo "Running all module tests..."
              
              # Run each module's tests if they exist
              ${builtins.concatStringsSep "\n" (map (name: ''
                if [ -d "${modules.${name}}/bin" ]; then
                  echo "Testing ${name}..."
                  find "${modules.${name}}/bin" -name "*test*" -executable | while read test; do
                    echo "  Running $test"
                    "$test" || exit 1
                  done
                fi
              '') (builtins.attrNames modules))}
              
              echo "All tests passed!"
            ''}";
          };
          
          # Run math-utils calculator demo
          calculator = {
            type = "app";
            program = "${modules.math-utils}/bin/calculator";
          };
          
          # Run logging demo
          log-demo = {
            type = "app";
            program = "${modules.logging}/bin/log-demo";
          };
        };
      }) // {
        # Expose the rules as an overlay for easy integration
        overlays.default = final: prev: {
          cmake-nix-rules = import ./nix { pkgs = final; };
        };
      };
}
