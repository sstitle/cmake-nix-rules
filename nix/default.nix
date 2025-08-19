# cmake-nix-rules main entry point with versioned API
{ pkgs }:

{
  # Current stable API (v1)
  v1 = import ./v1 { inherit pkgs; };
  
  # Convenience: expose v1 as default for backward compatibility
  inherit (import ./v1 { inherit pkgs; })
    mkModule mkLibrary mkExecutable
    discoverModules aggregateCompileCommands topologicalSort resolveModuleDependencies
    generateRootCMakeLists generateModuleCMakeLists
    defaultBuildConfig;
  
  # Future versions will be added here:
  # v2 = import ./v2 { inherit pkgs; };  # Future: enhanced features
  # v3 = import ./v3 { inherit pkgs; };  # Future: multi-build-system support
}
