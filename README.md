# cmake-nix-rules
Nix rules for generating CMake expressions

## Concept

A set of Nix functions that generate CMakeLists.txt and *.cmake files.

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

### Functions

Primary functions
- mkExecutable: compiles an executable that is an output "tool" or "test"
- mkLibrary: compiles a static or dynamic library

### Behavior

- Each module will generate a CMakeLists.txt which will be sym-linked into the module directory and either .gitignored OR marked as "DO NOT EDIT". These are for debugging purposes
- Each module will use the CMake built-in mechanism to generate a "compile_commands.json", modules that depend on other modules in the build tree will have string replacement performed so that all result "compile_commands.json" will have the correct locations in the original directory.
