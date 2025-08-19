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
        if lib.name == "test-lib" && lib.type == "static" && lib.targetType == "library"
        then "PASS: mkLibrary basic properties correct"
        else throw "mkLibrary properties wrong: name=${lib.name}, type=${lib.type}, targetType=${lib.targetType}";
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
        result1 = assertEqual "test-exe" exe.name "Executable name should be preserved";
        result2 = assertEqual "main.cpp" exe.entrypoint "Entrypoint should be preserved";
        result3 = assertEqual [] exe.sources "Default sources should be empty";
        result4 = assertEqual "executable" exe.targetType "Target type should be executable";
      in
        if result1 == "PASS Executable name should be preserved" && 
           result2 == "PASS Entrypoint should be preserved" &&
           result3 == "PASS Default sources should be empty" &&
           result4 == "PASS Target type should be executable"
        then "PASS: mkExecutable basic properties correct"
        else throw "One or more assertions failed";
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
        "PASS: discoverModules works correctly";
  }
  
  {
    name = "buildConfig-defaults";
    fn = _:
      let 
        config = cmake-rules.defaultBuildConfig;
        result1 = assertEqual "debug" config.buildType "Default build type should be debug";
        result2 = assertEqual "gcc" config.compiler "Default compiler should be gcc";
        result3 = assertEqual "20" config.cppStandard "Default C++ standard should be 20";
        result4 = assertEqual "ninja" config.generator "Default generator should be ninja";
        result5 = assertEqual "cmake" config.buildSystem "Default build system should be cmake";
      in
        if result1 == "PASS Default build type should be debug" &&
           result2 == "PASS Default compiler should be gcc" &&
           result3 == "PASS Default C++ standard should be 20" &&
           result4 == "PASS Default generator should be ninja" &&
           result5 == "PASS Default build system should be cmake"
        then "PASS: buildConfig defaults correct"
        else throw "One or more buildConfig assertions failed";
  }
]
