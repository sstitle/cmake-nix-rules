# mkModule function for creating module derivations
{ pkgs }:

{ name
, dependencies ? []        # Internal module dependencies (strings)
, externalDeps ? []        # External nixpkgs dependencies 
, fetchContentDeps ? []    # FetchContent dependencies
, buildConfig ? {}
, targets
, src ? null  # Source directory (will be auto-detected if null)
, internalDeps ? []        # Resolved internal module derivations (passed by dependency resolver)
}:

let
  utils = import ./utils.nix { inherit pkgs; };
  cmakeGen = import ./cmake-generation.nix { inherit pkgs; };
  
  # Merge with default build config (v1)
  defaultConfig = {
    buildType = "debug";
    compiler = "gcc";
    cppStandard = "20";
    generator = "ninja";
    buildSystem = "cmake";
    features = {
      sanitizers = [];
      lto = false;
      static = false;
      parallelJobs = "auto";
    };
  };
  
  finalBuildConfig = pkgs.lib.recursiveUpdate defaultConfig buildConfig;
  
  # Validate targets
  validateTargets = targets:
    if (!builtins.isAttrs targets || targets == {})
    then throw "Module '${name}' must have at least one target"
    else true;
    
  # Generate CMakeLists.txt for this module
  moduleCMakeLists = cmakeGen.generateModuleCMakeLists {
    inherit name targets externalDeps fetchContentDeps;
    dependencies = internalDeps;  # Pass resolved internal dependencies
    buildConfig = finalBuildConfig;
  };

in pkgs.stdenv.mkDerivation {
  pname = "${name}-module";
  version = "0.1.0";
  
  src = if src != null then src else ./.;
  
  nativeBuildInputs = with pkgs; [
    cmake
    pkg-config
  ] ++ (if finalBuildConfig.generator == "ninja" then [ ninja ] else [])
    ++ (if finalBuildConfig.compiler == "clang" then [ clang ] else [ gcc ]);
  
  buildInputs = (map (dep: 
    if builtins.isAttrs dep && dep ? pkg 
    then dep.pkg 
    else dep
  ) externalDeps) ++ internalDeps;
  
  # Validation
  __validate = validateTargets targets;
  
  configurePhase = ''
    runHook preConfigure
    
    # Create build directory
    mkdir -p build
    cd build
    
    # Write the generated CMakeLists.txt
    cp ${moduleCMakeLists} ../CMakeLists.txt
    
    # Configure with CMake
    cmake .. \
      -G ${if finalBuildConfig.generator == "ninja" then "Ninja" else "Unix Makefiles"} \
      -DCMAKE_BUILD_TYPE=${finalBuildConfig.buildType} \
      -DCMAKE_CXX_STANDARD=${finalBuildConfig.cppStandard} \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    
    runHook postConfigure
  '';
  
  buildPhase = ''
    runHook preBuild
    
    # Build all targets with parallel jobs
    ${if finalBuildConfig.features.parallelJobs == "auto" then ''
      cmake --build . --parallel
    '' else ''
      cmake --build . --parallel ${toString finalBuildConfig.features.parallelJobs}
    ''}
    
    runHook postBuild
  '';
  
  installPhase = ''
    runHook preInstall
    
    # Create output structure
    mkdir -p $out/{bin,lib,include,share}
    
    # Install built artifacts
    find . -name "*.a" -o -name "*.so" | xargs -I {} cp {} $out/lib/ || true
    find . -perm -111 -type f ! -name "*.so" | xargs -I {} cp {} $out/bin/ || true
    
    # Copy headers if they exist
    if [ -d ../inc ]; then
      cp -r ../inc/* $out/include/
    fi
    
    # Copy compile_commands.json
    if [ -f compile_commands.json ]; then
      cp compile_commands.json $out/share/
    fi
    
    runHook postInstall
  '';
  
  # Expose module metadata
  passthru = {
    moduleName = name;
    moduleTargets = targets;
    moduleDependencies = dependencies;  # Original dependency names (strings)
    resolvedDependencies = internalDeps;  # Actual resolved derivations
    moduleBuildConfig = finalBuildConfig;
  };
}
