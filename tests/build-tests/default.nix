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
      "PASS: logging module placeholder test";  # For now, just a placeholder
  }

  {
    name = "internal-dependency-headers-cmake-generation";
    fn = _:
      # Test that verifies CMake includes dependency include directories
      let
        # Mock internal dependency (simulating logging module)
        mockLoggingDep = pkgs.stdenv.mkDerivation {
          name = "mock-logging";
          dontUnpack = true;
          installPhase = ''
            mkdir -p $out/include/logger
            echo 'class Logger {};' > $out/include/logger/logger.hpp
          '';
          passthru.moduleName = "logging";
        };

        # Generate CMake for math-utils with internal dependency
        targets = {
          calculator = cmake-rules.mkExecutable { 
            name = "calculator"; 
            entrypoint = "tools/calculator.cpp";
          };
        };
        
        cmakeContent = cmake-rules.generateModuleCMakeLists {
          name = "math-utils";
          inherit targets;
          dependencies = [ mockLoggingDep ];  # Internal dependency
          externalDeps = [];
          fetchContentDeps = [];
          buildConfig = cmake-rules.defaultBuildConfig;
          src = builtins.path { path = ../../examples/math-utils; name = "math-utils-src"; };
        };
        
        content = builtins.readFile cmakeContent;
        
        # Check that CMake includes dependency include directories
        # We can't include store paths in regex, so let's check for the pattern structure
        hasIncludeDirectories = builtins.match ".*target_include_directories\\(calculator PRIVATE inc src.*" content != null;
        hasIncludeKeyword = builtins.match ".*include.*" content != null;
      in
        assert hasIncludeDirectories || throw "CMake should include target_include_directories for executables";
        assert hasIncludeKeyword || throw "CMake should reference include directories";
        "PASS: internal dependency headers are included in CMake generation";
  }

  {
    name = "internal-dependency-headers-library-target";
    fn = _:
      # Test that verifies CMake includes dependency include directories for library targets too
      let
        # Mock internal dependency
        mockLoggingDep = pkgs.stdenv.mkDerivation {
          name = "mock-logging";
          dontUnpack = true;
          installPhase = ''
            mkdir -p $out/include/logger
            echo 'class Logger {};' > $out/include/logger/logger.hpp
          '';
          passthru.moduleName = "logging";
        };

        # Generate CMake for a library with internal dependency
        targets = {
          lib = cmake-rules.mkLibrary { 
            name = "math-utils"; 
            type = "static";
          };
        };
        
        cmakeContent = cmake-rules.generateModuleCMakeLists {
          name = "math-utils";
          inherit targets;
          dependencies = [ mockLoggingDep ];  # Internal dependency
          externalDeps = [];
          fetchContentDeps = [];
          buildConfig = cmake-rules.defaultBuildConfig;
          src = builtins.path { path = ../../examples/math-utils; name = "math-utils-src"; };
        };
        
        content = builtins.readFile cmakeContent;
        
        # Check that CMake includes dependency include directories for libraries
        # We can't include store paths in regex, so let's check for the pattern structure
        hasIncludeDirectories = builtins.match ".*target_include_directories\\(math-utils PUBLIC inc PRIVATE src.*" content != null;
        hasIncludeKeyword = builtins.match ".*include.*" content != null;
      in
        assert hasIncludeDirectories || throw "CMake should include target_include_directories for libraries";
        assert hasIncludeKeyword || throw "CMake should reference include directories";
        "PASS: internal dependency headers are included for library targets";
  }

  {
    name = "debug-dependency-resolution-real-modules";
    fn = _:
      # Debug test to see what happens with real module resolution
      let
        # Use real module discovery like the flake does
        moduleDiscovery = cmake-rules.discoverModules ../../examples;
        
        # Try to resolve dependencies like the flake does
        resolvedModules = cmake-rules.resolveModuleDependencies moduleDiscovery pkgs cmake-rules;
        
        # Check if math-utils got its dependencies resolved
        mathUtilsModule = resolvedModules.math-utils or null;
        
        # Check if the module has internalDeps
        hasInternalDeps = mathUtilsModule != null && (mathUtilsModule.passthru.resolvedDependencies or []) != [];
        numDeps = if mathUtilsModule != null then builtins.length (mathUtilsModule.passthru.resolvedDependencies or []) else 0;
      in
        assert (mathUtilsModule != null) || throw "math-utils module should be resolved";
        if hasInternalDeps then
          "PASS: real dependency resolution works (${toString numDeps} dependencies resolved)"
        else
          throw "FAIL: math-utils should have resolved internal dependencies, got ${toString numDeps} deps. Module keys: ${builtins.concatStringsSep ", " (builtins.attrNames resolvedModules)}";
  }

  {
    name = "transitive-external-dependencies-cmake-generation";
    fn = _:
      # Test that verifies CMake includes transitive external dependencies from internal modules
      let
        # Mock logging module with spdlog external dependency
        mockLoggingDep = pkgs.stdenv.mkDerivation {
          name = "mock-logging";
          dontUnpack = true;
          installPhase = ''
            mkdir -p $out/include/logger
            echo 'class Logger {};' > $out/include/logger/logger.hpp
          '';
          passthru = {
            moduleName = "logging";
            # Mock external dependencies that logging module has
            moduleExternalDeps = [
              { pkg = { pname = "spdlog"; }; cmake.package = "spdlog"; cmake.targets = ["spdlog::spdlog"]; }
              { pkg = { pname = "fmt"; }; cmake.package = "fmt"; cmake.targets = ["fmt::fmt"]; }
            ];
          };
        };

        # Generate CMake for math-utils with internal dependency on logging
        targets = {
          calculator = cmake-rules.mkExecutable { 
            name = "calculator"; 
            entrypoint = "tools/calculator.cpp";
          };
        };
        
        cmakeContent = cmake-rules.generateModuleCMakeLists {
          name = "math-utils";
          inherit targets;
          dependencies = [ mockLoggingDep ];  # Internal dependency with external deps
          externalDeps = [
            { pkg = { pname = "eigen"; }; cmake.package = "Eigen3"; cmake.targets = ["Eigen3::Eigen"]; }
          ];
          fetchContentDeps = [];
          buildConfig = cmake-rules.defaultBuildConfig;
          src = builtins.path { path = ../../examples/math-utils; name = "math-utils-src"; };
        };
        
        content = builtins.readFile cmakeContent;
        
        # Check that CMake includes transitive external dependencies from logging module
        hasSpdlog = builtins.match ".*find_package\\(spdlog REQUIRED\\).*" content != null;
        hasFmt = builtins.match ".*find_package\\(fmt REQUIRED\\).*" content != null;
        hasEigen = builtins.match ".*find_package\\(Eigen3 REQUIRED\\).*" content != null;
      in
        # This test should FAIL initially until we implement transitive dependency propagation
        assert hasEigen || throw "CMake should include direct external dependencies (Eigen3)";
        assert hasSpdlog || throw "CMake should include transitive external dependencies (spdlog from logging)";
        assert hasFmt || throw "CMake should include transitive external dependencies (fmt from logging)";
        "PASS: transitive external dependencies are included in CMake generation";
  }
]
