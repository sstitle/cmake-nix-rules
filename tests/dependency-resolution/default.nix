# Tests for dependency resolution and topological sorting
{ pkgs, cmake-rules, testUtils }:

let
  inherit (testUtils) assert assertEqual assertThrows;
  
  # Mock module data for testing
  mockModules = [
    {
      name = "no-deps";
      nixFile = pkgs.writeText "no-deps.nix" ''
        { pkgs, cmake-nix-rules }:
        let inherit (cmake-nix-rules) mkModule mkLibrary;
        in mkModule {
          name = "no-deps";
          dependencies = [];
          targets = { lib = mkLibrary { name = "no-deps"; }; };
        }
      '';
      path = "/fake/no-deps";
    }
    {
      name = "single-dep";
      nixFile = pkgs.writeText "single-dep.nix" ''
        { pkgs, cmake-nix-rules }:
        let inherit (cmake-nix-rules) mkModule mkLibrary;
        in mkModule {
          name = "single-dep";
          dependencies = [ "no-deps" ];
          targets = { lib = mkLibrary { name = "single-dep"; }; };
        }
      '';
      path = "/fake/single-dep";
    }
    {
      name = "chain-dep";
      nixFile = pkgs.writeText "chain-dep.nix" ''
        { pkgs, cmake-nix-rules }:
        let inherit (cmake-nix-rules) mkModule mkLibrary;
        in mkModule {
          name = "chain-dep";
          dependencies = [ "single-dep" ];
          targets = { lib = mkLibrary { name = "chain-dep"; }; };
        }
      '';
      path = "/fake/chain-dep";
    }
  ];
  
  # Mock circular dependency modules
  circularModules = [
    {
      name = "circular-a";
      nixFile = pkgs.writeText "circular-a.nix" ''
        { pkgs, cmake-nix-rules }:
        let inherit (cmake-nix-rules) mkModule mkLibrary;
        in mkModule {
          name = "circular-a";
          dependencies = [ "circular-b" ];
          targets = { lib = mkLibrary { name = "circular-a"; }; };
        }
      '';
      path = "/fake/circular-a";
    }
    {
      name = "circular-b";
      nixFile = pkgs.writeText "circular-b.nix" ''
        { pkgs, cmake-nix-rules }:
        let inherit (cmake-nix-rules) mkModule mkLibrary;
        in mkModule {
          name = "circular-b";
          dependencies = [ "circular-a" ];
          targets = { lib = mkLibrary { name = "circular-b"; }; };
        }
      '';
      path = "/fake/circular-b";
    }
  ];

in [
  {
    name = "topologicalSort-empty-list";
    fn = _: 
      let result = cmake-rules.topologicalSort [];
      in assertEqual [] result "Empty list should return empty list";
  }
  
  {
    name = "topologicalSort-single-module-no-deps";
    fn = _:
      let 
        modules = [ (builtins.head mockModules) ];  # no-deps module
        result = cmake-rules.topologicalSort modules;
      in assert (builtins.length result == 1) "Should return single module";
  }
  
  {
    name = "topologicalSort-simple-dependency-chain";
    fn = _:
      let 
        # Test with no-deps, single-dep, chain-dep (should be sorted in that order)
        modules = mockModules;
        result = cmake-rules.topologicalSort modules;
        names = map (m: m.name) result;
      in 
        # no-deps should come first, then single-dep, then chain-dep
        assert (builtins.length result == 3) "Should return all 3 modules" &&
        assertEqual "no-deps" (builtins.head names) "no-deps should be first" &&
        assertEqual "single-dep" (builtins.elemAt names 1) "single-dep should be second" &&
        assertEqual "chain-dep" (builtins.elemAt names 2) "chain-dep should be third";
  }
  
  {
    name = "topologicalSort-detects-circular-dependency";
    fn = _: 
      assertThrows (_: cmake-rules.topologicalSort circularModules) 
        "Circular dependency should be detected";
  }
  
  {
    name = "dependency-extraction-works";
    fn = _:
      let
        # Test the dependency extraction logic used in topologicalSort
        getDependencies = moduleInfo:
          let 
            moduleNix = import moduleInfo.nixFile { 
              inherit pkgs; 
              cmake-nix-rules = { 
                mkModule = args: args; 
                mkLibrary = args: args; 
                mkExecutable = args: args; 
              }; 
            };
          in moduleNix.dependencies or [];
        
        noDeps = getDependencies (builtins.head mockModules);
        singleDep = getDependencies (builtins.elemAt mockModules 1);
        chainDep = getDependencies (builtins.elemAt mockModules 2);
      in
        assertEqual [] noDeps "no-deps should have no dependencies" &&
        assertEqual ["no-deps"] singleDep "single-dep should depend on no-deps" &&
        assertEqual ["single-dep"] chainDep "chain-dep should depend on single-dep";
  }
  
  {
    name = "real-modules-dependency-extraction";
    fn = _:
      let
        # Test with actual example modules
        exampleModules = cmake-rules.discoverModules ../examples;
        getDependencies = moduleInfo:
          let 
            moduleNix = import moduleInfo.nixFile { 
              inherit pkgs; 
              cmake-nix-rules = { 
                mkModule = args: args; 
                mkLibrary = args: args; 
                mkExecutable = args: args; 
              }; 
            };
          in moduleNix.dependencies or [];
        
        moduleDepMap = builtins.listToAttrs (map (m: {
          name = m.name;
          value = getDependencies m;
        }) exampleModules);
        
      in
        assertEqual [] (moduleDepMap.logging or []) "logging should have no dependencies" &&
        assertEqual ["logging"] (moduleDepMap.math-utils or []) "math-utils should depend on logging";
  }
]
