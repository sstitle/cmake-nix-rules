# Tests for internal dependency resolution
{ pkgs, cmake-rules, testUtils }:

let
  inherit (testUtils) assertEqual;

in [
  {
    name = "discoverModules-reads-dependencies";
    fn = _:
      let
        modules = cmake-rules.discoverModules ../../examples;
        mathUtils = builtins.head (builtins.filter (m: m.name == "math-utils") modules);
        logging = builtins.head (builtins.filter (m: m.name == "logging") modules);
      in
        # Test that discoverModules correctly reads the dependencies field
        assert (builtins.isList mathUtils.dependencies) "math-utils should have dependencies list";
        assertEqual ["logging"] mathUtils.dependencies "math-utils should depend on logging";
        assertEqual [ ] logging.dependencies "logging should have no dependencies";
        true;
  }

  {
    name = "module-definition-exposes-dependencies";
    fn = _:
      let
        # Import the module definition directly to check its structure
        mathUtilsModule = (import ../../examples/math-utils { 
          inherit pkgs; 
          cmake-nix-rules = cmake-rules; 
        });
      in
        # Test that the module exposes its dependencies in passthru
        assert (mathUtilsModule ? passthru) "Module should have passthru";
        assert (mathUtilsModule.passthru ? moduleDependencies) "Module should expose moduleDependencies";
        assertEqual ["logging"] mathUtilsModule.passthru.moduleDependencies "Module should expose correct dependencies";
        true;
  }

  {
    name = "resolved-dependencies-provide-headers";
    fn = _:
      let
        # Test that when dependencies are resolved, they provide the include paths
        resolved = cmake-rules.resolveModuleDependencies [
          { name = "logging"; path = ../../examples/logging; }
          { name = "math-utils"; path = ../../examples/math-utils; }
        ];
        mathUtilsModule = builtins.head (builtins.filter (m: m.pname == "math-utils-module") resolved.modules);
      in
        # Test that math-utils has resolved dependencies with include paths
        assert (mathUtilsModule ? passthru) "Resolved module should have passthru";
        assert (mathUtilsModule.passthru ? resolvedDependencies) "Module should have resolved dependencies";
        assertEqual 1 (builtins.length mathUtilsModule.passthru.resolvedDependencies) "Should have one resolved dependency";
        true;
  }

  {
    name = "cmake-generation-includes-internal-deps";
    fn = _:
      let
        # Test that CMake generation includes internal dependencies
        mockLoggingDep = {
          pname = "logging-module";
          passthru.moduleName = "logging";
        };
        targets = {
          lib = cmake-rules.mkLibrary { name = "test-lib"; };
        };
        cmakeContent = cmake-rules.generateModuleCMakeLists {
          name = "test-module";
          inherit targets;
          dependencies = [mockLoggingDep];
          externalDeps = [];
          fetchContentDeps = [];
          buildConfig = cmake-rules.defaultBuildConfig;
          src = /tmp;  # dummy path
        };
        content = builtins.readFile cmakeContent;
      in
        # Test that the generated CMake includes the internal dependency
        assert (builtins.match ".*add_library\\(logging STATIC IMPORTED\\).*" content != null) "Should declare logging as imported target";
        assert (builtins.match ".*INTERFACE_INCLUDE_DIRECTORIES.*" content != null) "Should set include directories";
        true;
  }

  {
    name = "cmake-links-internal-deps";
    fn = _:
      let
        # Test that executables are linked to internal dependencies
        mockLoggingDep = {
          pname = "logging-module";
          passthru.moduleName = "logging";
        };
        targets = {
          exe = cmake-rules.mkExecutable { name = "test-exe"; entrypoint = "main.cpp"; };
        };
        cmakeContent = cmake-rules.generateModuleCMakeLists {
          name = "test-module";
          inherit targets;
          dependencies = [mockLoggingDep];
          externalDeps = [];
          fetchContentDeps = [];
          buildConfig = cmake-rules.defaultBuildConfig;
          src = /tmp;  # dummy path
        };
        content = builtins.readFile cmakeContent;
      in
        # Test that the executable is linked to the internal dependency
        assert (builtins.match ".*target_link_libraries\\(test-exe logging\\).*" content != null) "Should link executable to internal dependency";
        true;
  }
]
