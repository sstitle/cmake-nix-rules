# Math utilities module example
{ pkgs, cmake-nix-rules }:

let
  inherit (cmake-nix-rules) mkModule mkLibrary mkExecutable;
  
in mkModule {
  name = "math-utils";
  dependencies = [ "logging" ];     # Internal module dependencies (by name)
  externalDeps = [ 
    # Detailed format for Eigen since CMake package name is "Eigen3"
    { pkg = pkgs.eigen; cmake.package = "Eigen3"; cmake.targets = ["Eigen3::Eigen"]; }
  ];
  fetchContentDeps = [];            # CMake FetchContent dependencies (escape hatch)
  
  # Set source directory to current directory
  src = ./.;
  
  targets = {
    # Primary library (auto-includes src/ and inc/math-utils/)
    lib = mkLibrary {
      name = "math-utils";
      type = "static";
    };
    
    # Calculator executable
    calculator = mkExecutable {
      name = "calculator";
      entrypoint = "tools/calculator.cpp";
    };
    
    # Vector tests
    vector-tests = mkExecutable {
      name = "vector-tests";
      entrypoint = "tests/vector_test.cpp";
    };
    
    # Matrix tests
    matrix-tests = mkExecutable {
      name = "matrix-tests";
      entrypoint = "tests/matrix_test.cpp";
    };
  };
}
