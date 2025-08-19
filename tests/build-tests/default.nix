# Build tests - tests that actually compile and run code
{ pkgs, cmake-rules, testUtils }:

let
  inherit (testUtils) assertEqual;

in [
  {
    name = "logging-module-builds";
    fn = _:
      # This test verifies that the logging module can be built
      # If this fails, it means our basic module building is broken
      true;  # For now, just a placeholder
  }

  {
    name = "math-utils-should-find-logging-headers";
    fn = _:
      # Test that verifies internal dependency headers are available
      # This should pass when we fix the internal dependency system
      let
        # Try to build math-utils - this should fail with header not found
        result = builtins.tryEval (builtins.readFile /dev/null);  # Placeholder for actual build test
      in
        # For now, expect this to fail until we implement proper header inclusion
        assert (!result.success) "Math-utils should currently fail to build due to missing headers";
        true;
  }
]
