# Logging module example with spdlog external dependency
{ pkgs, cmake-nix-rules }:

let
  inherit (cmake-nix-rules) mkModule mkLibrary mkExecutable;
  
in mkModule {
  name = "logging";
  dependencies = [];
  externalDeps = [ 
    pkgs.spdlog  # Simple format - CMake package name matches nixpkgs pname
    pkgs.fmt     # Simple format - CMake package name matches nixpkgs pname
  ];
  
  # Set source directory to current directory
  src = ./.;
  
  targets = {
    # Primary library using spdlog
    lib = mkLibrary {
      name = "logging";
      type = "static";
    };
    
    # Logging demo executable
    log-demo = mkExecutable {
      name = "log-demo";
      entrypoint = "tools/log_demo.cpp";
    };
    
    # Logger tests
    logger-tests = mkExecutable {
      name = "logger-tests";
      entrypoint = "tests/logger_test.cpp";
    };
  };
}
