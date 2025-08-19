# Tests for internal dependency resolution
{ pkgs, cmake-rules, testUtils }:

let
  inherit (testUtils) assertEqual;

in [
  {
    name = "discoverModules-finds-modules";
    fn = _:
      let
        modules = cmake-rules.discoverModules ../../examples;
        moduleNames = map (m: m.name) modules;
      in
        assert (builtins.length modules >= 2) "Should find at least 2 modules";
        assert (builtins.elem "math-utils" moduleNames) "Should find math-utils";
        assert (builtins.elem "logging" moduleNames) "Should find logging";
        true;
  }

  {
    name = "math-utils-has-dependencies";
    fn = _:
      let
        modules = cmake-rules.discoverModules ../../examples;
        mathUtils = builtins.head (builtins.filter (m: m.name == "math-utils") modules);
      in
        # This test will show us what's actually in mathUtils
        assert (mathUtils ? dependencies) "math-utils should have dependencies attribute";
        assertEqual ["logging"] mathUtils.dependencies "math-utils should depend on logging";
        true;
  }
]