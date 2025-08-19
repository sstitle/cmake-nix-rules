# cmake-nix-rules
Nix rules for generating CMake expressions

## Concept

A set of Nix functions that generate CMakeLists.txt and *.cmake files for C++ CMake monorepos. Each module becomes a separate Nix derivation, enabling efficient incremental builds where only changed modules and their dependents are rebuilt.

### Design Principles

- **Incremental Builds**: Each module is a separate Nix derivation with deterministic hashing based on source files, dependencies, and build configuration
- **Dependency Management**: 
  - **Internal Dependencies**: Module-to-module dependencies within the monorepo, referenced by name and resolved at flake evaluation time
  - **External Dependencies**: Third-party packages from nixpkgs (eigen, boost, spdlog, etc.) with native CMake integration
  - **FetchContent Dependencies**: Escape hatch for dependencies not available in nixpkgs, handled via CMake FetchContent
- **Build Configuration**: Structured inputs with explicitly enumerated options for reproducible builds across different configurations
- **Build System Flexibility**: Configurable compiler (gcc/clang), generator (ninja/make), with future support for alternative build systems (meson)
- **Versioned API**: Version-namespaced implementation (v1, v2, etc.) to enable breaking changes while maintaining backward compatibility
- **Convention over Configuration**: Standardized directory layout with implicit include paths, but explicit executable entrypoints

### Conventions

In order to facilitate simple rules, we expect certain conventions
-  Each "module" of C++ logic should have a default.nix file
-  Each "module" will generate a set of targets that can be: a) an executable, b) a static library, or c) a dynamic library
-  Each "module" will generate a "compile_commands.json"
-  Each "module" can have four folders:
  -   "inc" which containers a folder named by the package and contains headers exposed by the package
  -   "src" which contains source files for the package header implementation
  -   "tests" which contains source files for test executables
  -   "tools" which contains source files for output executables

### Example Module Structure

```
math-utils/                    # Module directory
├── default.nix              # Module definition
├── inc/
│   └── math-utils/           # Public headers (module name namespace)
│       ├── vector.hpp
│       └── matrix.hpp
├── src/                      # Implementation files
│   ├── vector.cpp
│   ├── matrix.cpp
│   └── internal.hpp          # Private headers
├── tests/                    # Test executables (auto-discovered)
│   ├── vector_test.cpp
│   └── matrix_test.cpp
└── tools/                    # Output executables
    ├── calculator.cpp        # Explicit entrypoint
    └── benchmark.cpp         # Another tool
```

### Functions

Primary functions
- mkExecutable: compiles an executable that is an output "tool" or "test"
- mkLibrary: compiles a static or dynamic library

### Function Interface

```nix
# Module definition (in default.nix)
mkModule = {
  name,                         # string: module name
  dependencies ? [],            # [string]: INTERNAL module names (e.g., ["logging", "math-utils"])
  externalDeps ? [],           # [package]: EXTERNAL nixpkgs packages (e.g., [pkgs.eigen, pkgs.boost])
  fetchContentDeps ? [],       # [attrset]: CMake FetchContent dependencies for packages not in nixpkgs
  buildConfig ? {},            # attrset: build configuration overrides
  targets                      # attrset: libraries and executables to build
}: derivation

# Library target
mkLibrary = {
  name,                        # string: library name
  type ? "static"              # enum: "static" | "dynamic"
  # Sources auto-discovered from src/ directory
  # Headers auto-discovered from inc/ and src/
}: target

# Executable target  
mkExecutable = {
  name,                        # string: executable name
  entrypoint,                  # path: main source file (e.g., "tools/calculator.cpp")
  sources ? []                 # [path]: additional source files
}: target

# Build configuration structure
buildConfig = {
  buildType ? "debug",         # enum: "debug" | "release" | "relWithDebInfo" | "minSizeRel"
  compiler ? "gcc",            # enum: "gcc" | "clang" | "msvc"
  cppStandard ? "20",         # enum: "17" | "20" | "23"
  generator ? "ninja",         # enum: "ninja" | "make" | "xcode" (default: ninja for performance)
  buildSystem ? "cmake",       # enum: "cmake" | "meson" (future: v1 is cmake-only)
  features ? {                # optional feature flags
    sanitizers ? [],          # [enum]: "address" | "undefined" | "thread"
    lto ? false,             # bool: link-time optimization
    static ? false           # bool: static linking
    parallelJobs ? "auto"    # int | "auto": parallel build jobs (default: auto-detect)
  }
}
```

### Example Usage

```nix
# math-utils/default.nix
{ pkgs, cmake-nix-rules }:
let
  inherit (cmake-nix-rules) mkModule mkLibrary mkExecutable;
in mkModule {
  name = "math-utils";
  dependencies = [ "logging" ];        # INTERNAL: Reference logging module by name
  externalDeps = [                     # EXTERNAL: Nixpkgs packages with CMake configuration
    { pkg = pkgs.eigen; cmake.package = "Eigen3"; cmake.targets = ["Eigen3::Eigen"]; }
    { pkg = pkgs.boost; cmake.package = "Boost"; cmake.targets = ["Boost::system"]; }
  ];
  fetchContentDeps = [                 # ESCAPE HATCH: For packages not in nixpkgs
    {
      name = "custom-lib";
      url = "https://github.com/user/custom-lib.git";
      tag = "v1.0.0";
    }
  ];
  
  targets = {
    # Primary library (auto-includes src/ and inc/math-utils/)
    lib = mkLibrary {
      name = "math-utils";
      type = "static";
    };
    
    # Calculator executable
    calculator = mkExecutable {
      name = "calculator";
      entrypoint = "tools/calculator.cpp";
    };
    
    # Tests (auto-discovered from tests/ directory)
    tests = mkExecutable {
      name = "math-utils-tests";
      entrypoint = "tests/test_main.cpp";
      sources = [ "tests/vector_test.cpp" "tests/matrix_test.cpp" ];
    };
  };
}
```

### Dependency Types Explained

#### Internal Dependencies (`dependencies`)
- **Purpose**: Module-to-module dependencies within your monorepo
- **Format**: Array of strings representing module names
- **Resolution**: Resolved automatically by the flake's module discovery system
- **CMake Integration**: Creates imported targets for linking
- **Example**: `dependencies = [ "logging", "math-utils" ]`

#### External Dependencies (`externalDeps`)
- **Purpose**: Third-party libraries available in nixpkgs
- **Format**: Array of nixpkgs packages OR attribute sets with detailed CMake configuration
- **Resolution**: Handled by Nix package manager
- **CMake Integration**: Uses `find_package()` with package config files
- **Formats**:
  - **Simple**: `pkgs.someLib` (assumes CMake package name equals nixpkgs pname)
  - **Detailed**: `{ pkg = pkgs.someLib; cmake.package = "CMakeName"; cmake.targets = ["Target1" "Target2"]; }`
- **Example**: 
  ```nix
  externalDeps = [
    # Detailed configuration for complex packages
    { pkg = pkgs.eigen; cmake.package = "Eigen3"; cmake.targets = ["Eigen3::Eigen"]; }
    { pkg = pkgs.boost; cmake.package = "Boost"; cmake.targets = ["Boost::system" "Boost::filesystem"]; }
    
    # Simple format when cmake package name matches nixpkgs pname
    pkgs.spdlog  # CMake: find_package(spdlog), target: spdlog::spdlog
    pkgs.fmt     # CMake: find_package(fmt), target: fmt::fmt
  ];
  ```

#### FetchContent Dependencies (`fetchContentDeps`)
- **Purpose**: Escape hatch for libraries not available in nixpkgs
- **Format**: Array of attribute sets with `name`, `url`, `tag`/`commit`
- **Resolution**: Downloaded and built via CMake FetchContent during build
- **CMake Integration**: Uses `FetchContent_Declare()` and `FetchContent_MakeAvailable()`
- **Example**: 
  ```nix
  fetchContentDeps = [
    {
      name = "nlohmann-json";
      url = "https://github.com/nlohmann/json.git";
      tag = "v3.11.2";
    }
  ];
  ```

### API Versioning

cmake-nix-rules uses a versioned API to enable future extensibility while maintaining backward compatibility:

#### Current Version: v1 (CMake-only)
- **Location**: `nix/v1/`
- **Build System**: CMake only
- **Generators**: Ninja (default), Make
- **Compilers**: GCC (default), Clang
- **Stability**: Stable API, no breaking changes

#### Future Versions
- **v2**: May include Meson support, enhanced dependency resolution
- **v3**: Potential support for other build systems, advanced caching

#### Version Selection
```nix
# In your flake.nix
cmake-nix-rules.lib.v1  # Current stable API
cmake-nix-rules.lib.v2  # Future: enhanced features (when available)
```

## Implementation Specification

### Monorepo Layout

```
my-cpp-project/
├── flake.nix                 # Root flake with cmake-nix-rules
├── flake.lock
├── modules/                  # All C++ modules
│   ├── math-utils/
│   │   ├── default.nix
│   │   ├── inc/math-utils/
│   │   ├── src/
│   │   ├── tests/
│   │   └── tools/
│   ├── network/
│   │   ├── default.nix
│   │   └── ...
│   └── ui/
│       ├── default.nix
│       └── ...
└── build-config.nix          # Global build configuration
```

### Flake Structure (flake-utils + per-system)

```nix
{
  description = "C++ monorepo with cmake-nix-rules";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    cmake-nix-rules.url = "github:user/cmake-nix-rules";
  };
  
  outputs = { self, nixpkgs, flake-utils, cmake-nix-rules }:
    flake-utils.lib.eachDefaultSystem (system: {
      packages = {
        default = # Full monorepo build with unified compile_commands.json
        math-utils = # Individual module builds
        network = 
        ui = 
      };
      
      apps = {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/main-executable";
        };
        build-all = {
          type = "app"; 
          program = "${pkgs.writeShellScript "build-all" "nix build"}";
        };
        test-all = {
          type = "app";
          program = # Script that runs all module tests
        };
        dev-setup = {
          type = "app";
          program = # Script that symlinks generated CMakeLists.txt for IDE support
        };
      };
      
      devShells.default = # Development environment with compilers and tools
    });
}
```

### Module Discovery

- Modules auto-discovered from `modules/*/default.nix` pattern
- Each module's `default.nix` must export a derivation using `mkModule`
- Module names derived from directory names
- Dependency resolution happens at flake evaluation time

### Global Build Configuration

```nix
# build-config.nix
{
  # Default configuration applied to all modules
  defaultBuildConfig = {
    buildType = "debug";
    compiler = "gcc";
    cppStandard = "20";
    features = {
      sanitizers = [ "address" ];
      lto = false;
      static = false;
    };
  };
  
  # Per-module overrides
  moduleOverrides = {
    "network" = {
      buildType = "release";  # Network module always optimized
    };
    "ui" = {
      features.static = true;  # UI statically linked
    };
  };
  
  # External dependencies available to all modules
  commonExternalDeps = pkgs: [
    pkgs.boost
    pkgs.gtest
    pkgs.spdlog
  ];
}
```

### CMake Generation Strategy

1. **Root CMakeLists.txt**: Generated at build time, includes all modules as subdirectories
2. **Module CMakeLists.txt**: Generated per module, handles:
   - Source file discovery from `src/` and `inc/`
   - Dependency linking (both internal modules and external packages)
   - Target creation (libraries, executables, tests)
   - `compile_commands.json` generation
3. **Inter-module Dependencies**: Expressed as CMake imported targets
4. **Path Management**: All generated files use absolute paths that get string-replaced post-build

### Compile Commands Aggregation

1. Each module generates its own `compile_commands.json` during build
2. Post-build step merges all module compilation databases
3. Path transformation replaces `/nix/store/<hash>-source/` with workspace-relative paths
4. Final `compile_commands.json` placed in build result with workspace-relative paths
5. `nix run .#dev-setup` symlinks result to workspace root for IDE integration

### Primary Usage Commands

```bash
# Build entire monorepo with unified compile_commands.json
nix build

# Build specific module
nix build .#math-utils

# Run main application
nix run

# Run all tests
nix run .#test-all

# Set up development environment with symlinked CMakeLists.txt
nix run .#dev-setup

# Enter development shell
nix develop
```

### Development Workflow

1. **`nix develop`**: Provides compilers, CMake, build tools, and language servers
2. **`nix run .#dev-setup`**: Symlinks generated CMakeLists.txt files to module directories for IDE support
3. **Incremental Development**: Changes to module source trigger only that module's rebuild
4. **IDE Integration**: Generated `compile_commands.json` points to original source locations

### String Replacement Strategy

```nix
# Post-build processing for compile_commands.json
let
  workspaceRoot = builtins.toString ./.;
  storePathPattern = "/nix/store/[a-z0-9]*-source";
in {
  # Replace store paths with workspace-relative paths
  fixCompileCommands = compileCommandsJson:
    builtins.replaceStrings 
      [ storePathPattern ]
      [ workspaceRoot ]
      compileCommandsJson;
}
```

### Behavior

- Each module generates a CMakeLists.txt symlinked to module directory (gitignored)
- Root CMakeLists.txt generated dynamically including all discovered modules
- Each module produces `compile_commands.json` with `/nix/store` paths
- Post-build aggregation merges and transforms paths to workspace-relative
- `nix build` produces result with unified `compile_commands.json`
- `nix run .#dev-setup` symlinks result to workspace for IDE integration

