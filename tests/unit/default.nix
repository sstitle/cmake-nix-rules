# Unit tests for core cmake-nix-rules functions
{ pkgs, cmake-rules, testUtils }:

let
  inherit (testUtils) assertEqual assertThrows;
  inherit (cmake-rules) mkModule mkLibrary mkExecutable;

in [
  {
    name = "mkLibrary-static-basic";
    fn = _:
      let 
        lib = mkLibrary { name = "test-lib"; type = "static"; };
      in
        assertEqual "test-lib" lib.name "Library name should be preserved";
        assertEqual "static" lib.type "Library type should be static";
        assertEqual "library" lib.targetType "Target type should be library";
        true;
  }
  
  {
    name = "mkLibrary-dynamic";
    fn = _:
      let 
        lib = mkLibrary { name = "test-lib"; type = "dynamic"; };
      in
        assertEqual "dynamic" lib.type "Library type should be dynamic";
  }
  
  {
    name = "mkLibrary-invalid-type";
    fn = _:
      assertThrows (_: mkLibrary { name = "test"; type = "invalid"; })
        "Invalid library type should throw error";
  }
  
  {
    name = "mkExecutable-basic";
    fn = _:
      let 
        exe = mkExecutable { 
          name = "test-exe"; 
          entrypoint = "main.cpp"; 
        };
      in
        assertEqual "test-exe" exe.name "Executable name should be preserved";
        assertEqual "main.cpp" exe.entrypoint "Entrypoint should be preserved";
        assertEqual [] exe.sources "Default sources should be empty";
        assertEqual "executable" exe.targetType "Target type should be executable";
  }
  
  {
    name = "mkExecutable-with-sources";
    fn = _:
      let 
        exe = mkExecutable { 
          name = "test-exe"; 
          entrypoint = "main.cpp";
          sources = ["util.cpp" "helper.cpp"];
        };
      in
        assertEqual ["util.cpp" "helper.cpp"] exe.sources "Sources should be preserved";
  }
  
  {
    name = "mkExecutable-empty-entrypoint";
    fn = _:
      assertThrows (_: mkExecutable { name = "test"; entrypoint = ""; })
        "Empty entrypoint should throw error";
  }
  
  {
    name = "mkModule-basic-structure";
    fn = _:
      let 
        module = mkModule {
          name = "test-module";
          dependencies = [];
          externalDeps = [];
          targets = {
            lib = mkLibrary { name = "test-lib"; };
          };
        };
      in
        # Check that it's a derivation
        assert (builtins.isAttrs module) "mkModule should return an attribute set";
        assert (module ? pname) "Module should have pname attribute";
        assertEqual "test-module-module" module.pname "Module pname should include -module suffix";
  }
  
  {
    name = "mkModule-empty-targets";
    fn = _:
      assertThrows (_: mkModule {
        name = "test";
        targets = {};
      }) "Empty targets should throw error";
  }
  
  {
    name = "discoverModules-basic";
    fn = _:
      let 
        modules = cmake-rules.discoverModules ../examples;
        moduleNames = map (m: m.name) modules;
      in
        assert (builtins.length modules >= 2) "Should discover at least 2 modules";
        assert (builtins.elem "logging" moduleNames) "Should discover logging module";
        assert (builtins.elem "math-utils" moduleNames) "Should discover math-utils module";
  }
  
  {
    name = "buildConfig-defaults";
    fn = _:
      let 
        config = cmake-rules.defaultBuildConfig;
      in
        assertEqual "debug" config.buildType "Default build type should be debug";
        assertEqual "gcc" config.compiler "Default compiler should be gcc";
        assertEqual "20" config.cppStandard "Default C++ standard should be 20";
        assertEqual "ninja" config.generator "Default generator should be ninja";
        assertEqual "cmake" config.buildSystem "Default build system should be cmake";
  }
]
