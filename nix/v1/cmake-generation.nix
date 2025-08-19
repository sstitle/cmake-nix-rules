# CMake generation utilities
{ pkgs }:

let
  inherit (pkgs) lib;
  
  # Generate CMakeLists.txt for a module
  generateModuleCMakeLists = { name, targets, dependencies ? [], externalDeps ? [], fetchContentDeps ? [], buildConfig }:
    let
      # Helper functions for CMake generation
      sanitizerFlags = lib.optionals (buildConfig.features.sanitizers != []) [
        "-fsanitize=${lib.concatStringsSep "," buildConfig.features.sanitizers}"
      ];
      
      ltoFlag = lib.optional buildConfig.features.lto "-flto";
      
      compilerFlags = sanitizerFlags ++ ltoFlag;
      
      # Generate target definitions
      generateTarget = targetName: target:
        if target.targetType == "library" then
          generateLibraryTarget targetName target
        else if target.targetType == "executable" then
          generateExecutableTarget targetName target
        else
          throw "Unknown target type: ${target.targetType}";
      
      generateLibraryTarget = targetName: target:
        let
          libType = if target.type == "static" then "STATIC" else "SHARED";
          # Discover source files using Nix
          sourceFiles = lib.filesystem.listFilesRecursive (src + "/src");
          cppSources = builtins.filter (file: 
            let ext = lib.strings.fileExtension (builtins.toString file);
            in builtins.elem ext ["cpp" "cc" "cxx" "c++"]
          ) sourceFiles;
          relativeSources = map (file: 
            lib.strings.removePrefix (builtins.toString src + "/") (builtins.toString file)
          ) cppSources;
          
          # Discover header files using Nix  
          headerFiles = lib.filesystem.listFilesRecursive (src + "/inc") ++ 
                       lib.filesystem.listFilesRecursive (src + "/src");
          cppHeaders = builtins.filter (file:
            let ext = lib.strings.fileExtension (builtins.toString file);
            in builtins.elem ext ["hpp" "hh" "hxx" "h++" "h"]
          ) headerFiles;
          relativeHeaders = map (file:
            lib.strings.removePrefix (builtins.toString src + "/") (builtins.toString file)
          ) cppHeaders;
        in ''
          # Library: ${targetName}
          set(${target.name}_SOURCES
            ${lib.concatStringsSep "\n    " relativeSources}
          )
          set(${target.name}_HEADERS
            ${lib.concatStringsSep "\n    " relativeHeaders}
          )
          
          add_library(${target.name} ${libType} ''${${target.name}_SOURCES})
          target_include_directories(${target.name} PUBLIC inc PRIVATE src)
          
          if(${target.name}_HEADERS)
            set_target_properties(${target.name} PROPERTIES PUBLIC_HEADER "''${${target.name}_HEADERS}")
          endif()
        '';
      
      generateExecutableTarget = targetName: target:
        let
          additionalSources = if target.sources != [] then
            lib.concatStringsSep " " target.sources
          else "";
        in ''
          # Executable: ${targetName}
          add_executable(${target.name} ${target.entrypoint} ${additionalSources})
          target_include_directories(${target.name} PRIVATE inc src)
        '';
      
      # Generate dependency linking
      generateDependencies = targets:
        let
          targetNames = lib.attrNames targets;
          linkCommands = map (targetName: 
            let target = targets.${targetName}; in
            ''
              # Link internal module dependencies for ${targetName}
              ${lib.concatStringsSep "\n" (map (dep: 
                "target_link_libraries(${target.name} ${dep.passthru.moduleName or dep.pname})"
              ) dependencies)}
            ''
          ) targetNames;
        in lib.concatStringsSep "\n" linkCommands;
      
      cmakeContent = ''
        cmake_minimum_required(VERSION 3.20)
        project(${name})
        
        # Set C++ standard
        set(CMAKE_CXX_STANDARD ${buildConfig.cppStandard})
        set(CMAKE_CXX_STANDARD_REQUIRED ON)
        
        # Set build type
        if(NOT CMAKE_BUILD_TYPE)
          set(CMAKE_BUILD_TYPE ${buildConfig.buildType})
        endif()
        
        # Compiler flags
        ${lib.optionalString (compilerFlags != []) ''
          set(CMAKE_CXX_FLAGS "''${CMAKE_CXX_FLAGS} ${lib.concatStringsSep " " compilerFlags}")
        ''}
        
        # Export compile commands
        set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
        
        # Internal module dependencies (imported targets)
        ${lib.concatStringsSep "\n" (map (dep: ''
          # Import ${dep.passthru.moduleName or dep.pname} module
          add_library(${dep.passthru.moduleName or dep.pname} STATIC IMPORTED)
          set_target_properties(${dep.passthru.moduleName or dep.pname} PROPERTIES
            IMPORTED_LOCATION "${dep}/lib/lib${dep.passthru.moduleName or dep.pname}.a"
            INTERFACE_INCLUDE_DIRECTORIES "${dep}/include"
          )
        '') dependencies)}
        
        # External dependencies (nixpkgs packages)
        ${lib.concatStringsSep "\n" (map (dep: 
          let
            # Handle both simple packages and detailed cmake configuration
            cmakePackage = if builtins.isAttrs dep && dep ? cmake && dep.cmake ? package
                          then dep.cmake.package
                          else if builtins.isAttrs dep && dep ? pkg
                          then dep.pkg.pname  # fallback to nixpkgs pname
                          else dep.pname;     # simple package format
          in "find_package(${cmakePackage} REQUIRED)"
        ) externalDeps)}
        
        # FetchContent dependencies (escape hatch)
        ${lib.optionalString (fetchContentDeps != []) ''
          include(FetchContent)
          ${lib.concatStringsSep "\n" (map (dep: ''
            FetchContent_Declare(
              ${dep.name}
              GIT_REPOSITORY ${dep.url}
              GIT_TAG ${dep.tag or dep.commit or "main"}
            )
          '') fetchContentDeps)}
          ${lib.concatStringsSep "\n" (map (dep: "FetchContent_MakeAvailable(${dep.name})") fetchContentDeps)}
        ''}
        
        # Targets
        ${lib.concatStringsSep "\n\n" (lib.mapAttrsToList generateTarget targets)}
        
        # Link dependencies
        ${generateDependencies targets}
        
        # Link external dependencies
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (targetName: target:
          lib.concatStringsSep "\n" (map (dep: 
            let
              # Extract cmake targets or fallback to common patterns
              cmakeTargets = if builtins.isAttrs dep && dep ? cmake && dep.cmake ? targets
                            then dep.cmake.targets
                            else if builtins.isAttrs dep && dep ? pkg
                            then ["${dep.pkg.pname}::${dep.pkg.pname}"]  # common pattern
                            else ["${dep.pname}::${dep.pname}"];         # simple package
            in lib.concatStringsSep "\n" (map (cmakeTarget: 
              "target_link_libraries(${target.name} ${cmakeTarget})"
            ) cmakeTargets)
          ) externalDeps)
        ) targets)}
        
        # Link executables to libraries within the same module
        ${let
          libraries = lib.filterAttrs (name: target: target.targetType == "library") targets;
          executables = lib.filterAttrs (name: target: target.targetType == "executable") targets;
          libraryNames = map (target: target.name) (lib.attrValues libraries);
        in lib.concatStringsSep "\n" (lib.mapAttrsToList (execName: execTarget:
          lib.concatStringsSep "\n" (map (libName: "target_link_libraries(${execTarget.name} ${libName})") libraryNames)
        ) executables)}
      '';
      
    in pkgs.writeText "CMakeLists.txt" cmakeContent;
  
  # Generate root CMakeLists.txt that includes all modules
  generateRootCMakeLists = modules:
    let
      cmakeContent = ''
        cmake_minimum_required(VERSION 3.20)
        project(MonorepoRoot)
        
        # Set C++ standard globally
        set(CMAKE_CXX_STANDARD 20)
        set(CMAKE_CXX_STANDARD_REQUIRED ON)
        
        # Export compile commands
        set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
        
        # Add all module subdirectories
        ${lib.concatStringsSep "\n" (map (module: "add_subdirectory(${module.path})") modules)}
      '';
      
    in pkgs.writeText "CMakeLists.txt" cmakeContent;

in {
  inherit generateModuleCMakeLists generateRootCMakeLists;
}
