# cmake-nix-rules main entry point
{ pkgs }:

let
  # Import individual components
  mkModule = import ./mkModule.nix { inherit pkgs; };
  mkLibrary = import ./mkLibrary.nix { inherit pkgs; };
  mkExecutable = import ./mkExecutable.nix { inherit pkgs; };
  cmakeGen = import ./cmake-generation.nix { inherit pkgs; };
  utils = import ./utils.nix { inherit pkgs; };

in rec {
  # Main API functions
  inherit mkModule mkLibrary mkExecutable;
  
  # Utility functions - discoverModules needs access to the main functions
  discoverModules = utils.discoverModules { inherit mkModule mkLibrary mkExecutable; };
  inherit (utils) aggregateCompileCommands topologicalSort resolveModuleDependencies;
  
  # CMake generation utilities
  inherit (cmakeGen) generateRootCMakeLists generateModuleCMakeLists;
  
  # Default build configuration (v1)
  defaultBuildConfig = {
    buildType = "debug";
    compiler = "gcc";
    cppStandard = "20";
    generator = "ninja";           # Default to Ninja for performance
    buildSystem = "cmake";         # v1 is CMake-only
    features = {
      sanitizers = [];
      lto = false;
      static = false;
      parallelJobs = "auto";       # Auto-detect CPU cores
    };
  };
}
