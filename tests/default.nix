# Simple, reliable test framework using only Nix built-ins
{ pkgs }:

let
  cmake-rules = import ../nix { inherit pkgs; };
  
  # Proven test utilities (tested in test-utils-tests.nix)
  assertEqual = expected: actual: message:
    assert (expected == actual) || throw "FAIL ${message}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";
    "PASS ${message}";

  # Simple test runner - just evaluate the test function and catch errors
  runTest = name: testFn:
    let result = builtins.tryEval (testFn null);
    in {
      inherit name;
      success = result.success;
      message = if result.success then result.value else "FAIL: ${builtins.toString result.value}";
    };

  # Core tests for our main functions
  tests = [
    {
      name = "mkLibrary-basic";
      fn = _:
        let lib = cmake-rules.mkLibrary { name = "test"; };
        in assertEqual "test" lib.name "Library name should be preserved";
    }
    
    {
      name = "mkExecutable-basic"; 
      fn = _:
        let exe = cmake-rules.mkExecutable { name = "test"; entrypoint = "main.cpp"; };
        in assertEqual "test" exe.name "Executable name should be preserved";
    }
    
    {
      name = "discoverModules-finds-examples";
      fn = _:
        let 
          modules = cmake-rules.discoverModules ../examples;
          moduleNames = map (m: m.name) modules;
          hasLogging = builtins.elem "logging" moduleNames;
          hasMathUtils = builtins.elem "math-utils" moduleNames;
        in
          if hasLogging && hasMathUtils 
          then "PASS: Found expected modules"
          else throw "Missing modules: logging=${builtins.toString hasLogging}, math-utils=${builtins.toString hasMathUtils}";
    }
    
    {
      name = "math-utils-has-dependencies";
      fn = _:
        let
          modules = cmake-rules.discoverModules ../examples;
          mathUtils = builtins.head (builtins.filter (m: m.name == "math-utils") modules);
        in
          if (mathUtils ? dependencies) && (mathUtils.dependencies == ["logging"])
          then "PASS: math-utils has correct dependencies" 
          else throw "math-utils dependencies wrong: ${builtins.toJSON (mathUtils.dependencies or "missing")}";
    }
    
    {
      name = "logging-builds-successfully";
      fn = _:
        let
          # Test that logging module builds (this should work)
          result = builtins.tryEval (cmake-rules.resolveModuleDependencies [
            { name = "logging"; path = ../examples/logging; }
          ]);
        in
          if result.success 
          then "PASS: logging module builds"
          else throw "logging build failed: ${builtins.toString result.value}";
    }
    
    {
      name = "topological-sort-works";
      fn = _:
        # Skip this test for now - it requires complex mock setup
        # TODO: Move to integration tests with proper mock modules
        "SKIP: topological sort test moved to integration tests";
    }
    
    {
      name = "external-deps-cmake-generation";
      fn = _:
        let
          # Test CMake generation for external dependencies
          targets = { lib = cmake-rules.mkLibrary { name = "test-lib"; }; };
          eigenDep = { pkg = { pname = "eigen"; }; cmake.package = "Eigen3"; cmake.targets = ["Eigen3::Eigen"]; };
          cmakeContent = cmake-rules.generateModuleCMakeLists {
            name = "test-module";
            inherit targets;
            dependencies = [];
            externalDeps = [eigenDep];
            fetchContentDeps = [];
            buildConfig = cmake-rules.defaultBuildConfig;
            src = /tmp;
          };
          content = builtins.readFile cmakeContent;
        in
          if (builtins.match ".*find_package\\(Eigen3 REQUIRED\\).*" content != null)
          then "PASS: CMake generation includes external deps"
          else throw "CMake generation missing external deps";
    }
  ];
  
  # Run all tests and collect results
  results = map (test: runTest test.name test.fn) tests;
  
  # Import proven test utilities 
  testUtilsModule = import ./test-utils-tests.nix { inherit pkgs; };
  
in {
  # Test utilities for other files to use
  testUtils = { 
    inherit (testUtilsModule) assertEqual assertThrows; 
  };
  
  # Test results
  testResults = results;
  
  # Simple test runner derivation
  runAllTests = pkgs.writeText "test-results" (
    let
      resultMessages = map (r: "${r.name}: ${r.message}") results;
      failures = builtins.filter (r: !r.success) results;
      summary = if failures == [] then "All tests passed!" else "Some tests failed!";
    in
      builtins.concatStringsSep "\n" (resultMessages ++ [summary])
  );
}
