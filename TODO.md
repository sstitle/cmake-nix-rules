# TODO List for cmake-nix-rules

## Completed Tasks ✅

- **setup-flake**: Create flake.nix with flake-utils and per-system pattern
- **create-core-functions**: Implement mkModule, mkLibrary, mkExecutable functions in nix/
- **cmake-generation**: Create CMake generation logic for modules and root CMakeLists.txt
- **example-math-utils**: Create examples/math-utils module with library, executable, and tests
- **build-config**: Implement global build configuration and per-module overrides
- **git-add-files**: Add all created files to git as they are created
- **create-logger-module**: Create logger module using spdlog as external dependency example
- **update-math-utils-eigen**: Update math-utils to use Eigen as external dependency
- **module-dependency-system**: Implement proper module discovery and inter-dependency resolution at flake level
- **update-flake-packages**: Update main flake.nix to discover modules and handle dependencies properly
- **fix-cmake-generation**: Fix CMake generation to handle external deps properly (find_package vs FetchContent)
- **build-system-config**: Add configurable build system options (gcc/clang, ninja/make, cmake/meson)
- **versioned-api**: Create versioned API structure (nix/v1/) for future flexibility
- **ninja-default**: Enable Ninja as default generator instead of make
- **restructure-nix**: Restructure nix/ directory with v1/ subdirectory
- **create-test-framework**: Create comprehensive test suite in tests/ directory
- **dependency-resolution**: Implement proper internal module dependency resolution with topological sorting
- **fix-cpp-compilation**: Fix C++ compilation errors in logging module (spdlog format strings)
- **external-deps-design**: Design and implement flexible external dependency specification
- **fix-test-framework**: Fix test framework to use built-in assert properly
- **test-internal-deps-headers**: Write test for internal dependency header inclusion
- **discover-dependencies**: Fix discoverModules to read dependencies field from module definitions
- **test-simple-framework**: Create simple, TDD-tested framework for testing

## In Progress Tasks 🚧

- **fix-internal-deps-headers**: Fix internal module dependency header inclusion - math-utils can't find logger/logger.hpp

## Pending Tasks 📋

- **compile-commands**: Implement compile_commands.json aggregation and path transformation
- **example-network**: Create examples/network module to demonstrate inter-module dependencies
- **example-ui**: Create examples/ui module as final integration example
- **dev-apps**: Create dev-setup, test-all, and build-all apps
- **tests**: Add tests to verify examples build and work correctly
- **unit-tests**: Add unit tests for individual functions (mkModule, mkLibrary, etc.)
- **integration-tests**: Add integration tests for module dependency resolution
- **build-tests**: Add tests that actually compile and run the example modules
- **cmake-output-tests**: Test generated CMakeLists.txt files are correct
- **run-all-tests**: Verify all functionality works with comprehensive test run

## Cancelled Tasks ❌

- **update-math-utils-logger**: Update math-utils to depend on logger module for internal dependency

## Current Status

The project has successfully implemented:
- Core Nix functions for creating modules, libraries, and executables
- Dependency discovery and resolution with topological sorting
- CMake generation with explicit file discovery (no GLOB)
- Flexible external dependency specification supporting both simple and detailed formats
- Test-driven development with simple, reliable test utilities

### Key Achievements:
1. **Dependency Resolution**: Successfully fixed the issue where `discoverModules` wasn't reading dependencies from module definitions
2. **External Dependencies**: Implemented a flexible system that allows users to specify CMake package names and targets explicitly
3. **Test Framework**: Created a simple, TDD-tested framework using only Nix built-ins
4. **Build System**: Supports multiple compilers (GCC/Clang), generators (Make/Ninja), and configurable options

### Current Issue:
The main remaining issue is that while dependency discovery works correctly, C++ compilation still fails because internal module headers aren't being made available during compilation. This is the next focus area for TDD resolution.

### Test Status:
Most core tests are passing:
- ✅ mkLibrary/mkExecutable basic functionality
- ✅ Module discovery finds example modules correctly  
- ✅ math-utils has correct dependencies (["logging"])
- ✅ Dependency resolution builds successfully
- ✅ CMake generation includes external dependencies correctly
- ❌ One topological sort test needs minor mock data fix

The project follows a test-driven development approach with systematic verification of each component.
