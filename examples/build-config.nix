# Global build configuration for examples
{ pkgs }:

{
  # Default configuration applied to all modules
  defaultBuildConfig = {
    buildType = "debug";
    compiler = "gcc";
    cppStandard = "20";
    features = {
      sanitizers = [ "address" ];
      lto = false;
      static = false;
    };
  };
  
  # Per-module overrides
  moduleOverrides = {
    "network" = {
      buildType = "release";  # Network module always optimized
    };
    "ui" = {
      features.static = true;  # UI statically linked
    };
  };
  
  # External dependencies available to all modules
  commonExternalDeps = [
    # Add common dependencies here as needed
    # pkgs.boost
    # pkgs.gtest
    # pkgs.spdlog
  ];
}
