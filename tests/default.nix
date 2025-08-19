# Test suite for cmake-nix-rules
{ pkgs }:

let
  cmake-rules = import ../nix { inherit pkgs; };
  
  # Test framework utilities
  testUtils = {
    # Assert that a condition is true
    assert = condition: message:
      if condition then true
      else throw "Test failed: ${message}";
    
    # Assert that two values are equal
    assertEqual = expected: actual: message:
      testUtils.assert (expected == actual) 
        "${message}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";
    
    # Assert that a function throws an error
    assertThrows = fn: message:
      let
        result = builtins.tryEval (fn {});
      in testUtils.assert (!result.success) 
         "${message}: expected function to throw, but it succeeded with ${builtins.toJSON result.value}";
    
    # Run a test and catch any errors
    runTest = name: testFn:
      let
        result = builtins.tryEval (testFn {});
      in {
        inherit name;
        success = result.success;
        error = if result.success then null else "Test threw: ${builtins.toString result.value}";
        result = if result.success then result.value else null;
      };
  };
  
  # Import individual test modules
  unitTests = import ./unit { inherit pkgs cmake-rules testUtils; };
  integrationTests = import ./integration { inherit pkgs cmake-rules testUtils; };
  dependencyTests = import ./dependency-resolution { inherit pkgs cmake-rules testUtils; };
  externalDepsTests = import ./external-deps { inherit pkgs cmake-rules testUtils; };
  
  # Collect all tests
  allTests = unitTests ++ integrationTests ++ dependencyTests ++ externalDepsTests;
  
  # Run all tests and summarize results
  testResults = map (test: testUtils.runTest test.name test.fn) allTests;
  
  # Summary of test results
  summary = {
    total = builtins.length testResults;
    passed = builtins.length (builtins.filter (r: r.success) testResults);
    failed = builtins.length (builtins.filter (r: !r.success) testResults);
    results = testResults;
  };
  
  # Generate test report
  testReport = pkgs.writeText "test-report.txt" ''
    CMAKE-NIX-RULES TEST REPORT
    ===========================
    
    Total tests: ${toString summary.total}
    Passed: ${toString summary.passed}
    Failed: ${toString summary.failed}
    
    ${if summary.failed > 0 then ''
      FAILED TESTS:
      ${builtins.concatStringsSep "\n" (map (r: 
        if !r.success then "❌ ${r.name}: ${r.error}" else ""
      ) testResults)}
    '' else "✅ All tests passed!"}
    
    DETAILED RESULTS:
    ${builtins.concatStringsSep "\n" (map (r: 
      "${if r.success then "✅" else "❌"} ${r.name}"
    ) testResults)}
  '';

in {
  inherit testUtils summary testResults;
  
  # Main test runner
  runAllTests = pkgs.runCommand "cmake-nix-rules-tests" {} ''
    mkdir -p $out
    cp ${testReport} $out/test-report.txt
    
    # Exit with error code if any tests failed
    ${if summary.failed > 0 then ''
      echo "Tests failed! See report for details."
      cat $out/test-report.txt
      exit 1
    '' else ''
      echo "All tests passed!"
      cat $out/test-report.txt
    ''}
  '';
  
  # Individual test categories
  inherit unitTests integrationTests dependencyTests externalDepsTests;
}
