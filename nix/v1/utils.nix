# Utility functions for cmake-nix-rules
{ pkgs }:

let
  inherit (pkgs) lib;
in rec {
  # Discover modules from a directory pattern
  discoverModules = cmakeRules: modulesDir:
    let
      # Find all default.nix files in subdirectories
      moduleEntries = builtins.readDir modulesDir;
      moduleNames = lib.attrNames (lib.filterAttrs (name: type: type == "directory") moduleEntries);
      
      # Check each directory for default.nix
      validModules = lib.filter (name: 
        builtins.pathExists "${modulesDir}/${name}/default.nix"
      ) moduleNames;
      
    in map (name: 
      let
        modulePath = "${modulesDir}/${name}";
        # Import the module to read its configuration
        moduleConfig = import "${modulePath}/default.nix" { 
          inherit pkgs; 
          cmake-nix-rules = cmakeRules; 
        };
      in {
        inherit name;
        path = modulePath;
        nixFile = "${modulePath}/default.nix";
        # Extract dependencies from the module definition
        dependencies = moduleConfig.passthru.moduleDependencies or [];
      }
    ) validModules;
  
  # Aggregate compile_commands.json from multiple modules
  aggregateCompileCommands = modules: workspaceRoot:
    let
      # Collect all compile_commands.json files
      compileCommandsFiles = map (module: "${module}/share/compile_commands.json") modules;
      
      # Script to merge and transform paths
      mergeScript = pkgs.writeShellScript "merge-compile-commands" ''
        echo "["
        first=true
        for file in ${lib.concatStringsSep " " compileCommandsFiles}; do
          if [ -f "$file" ]; then
            if [ "$first" = true ]; then
              first=false
            else
              echo ","
            fi
            # Remove the outer brackets and transform paths
            ${pkgs.jq}/bin/jq -r '.[].file |= gsub("/nix/store/[^/]+-source"; "${workspaceRoot}") | .[]' "$file" | \
            ${pkgs.jq}/bin/jq -s '.'
          fi
        done
        echo "]"
      '';
      
    in pkgs.runCommand "aggregated-compile-commands" {} ''
      mkdir -p $out
      ${mergeScript} > $out/compile_commands.json
    '';
  
  # Auto-discover source files in standard directories
  discoverSources = moduleDir:
    let
      srcDir = "${moduleDir}/src";
      incDir = "${moduleDir}/inc";
      testsDir = "${moduleDir}/tests";
      toolsDir = "${moduleDir}/tools";
      
      # Helper to find files with extensions
      findFiles = dir: extensions:
        if builtins.pathExists dir
        then lib.filter (f: lib.any (ext: lib.hasSuffix ext f) extensions) 
                       (lib.filesystem.listFilesRecursive dir)
        else [];
      
      cppExtensions = [ ".cpp" ".cc" ".cxx" ".c++" ];
      headerExtensions = [ ".hpp" ".hh" ".hxx" ".h++" ".h" ];
      
    in {
      sources = findFiles srcDir cppExtensions;
      headers = (findFiles incDir headerExtensions) ++ (findFiles srcDir headerExtensions);
      tests = findFiles testsDir cppExtensions;
      tools = findFiles toolsDir cppExtensions;
    };
  
  # Transform store paths to workspace-relative paths
  transformCompileCommands = compileCommandsJson: workspaceRoot:
    let
      storePathPattern = "/nix/store/[a-z0-9]*-source";
    in builtins.replaceStrings 
         [ storePathPattern ]
         [ workspaceRoot ]
         compileCommandsJson;
  
  # Topological sort for dependency resolution
  topologicalSort = modules:
    let
      # Extract dependency graph
      getDependencies = moduleInfo:
        let 
          moduleNix = import moduleInfo.nixFile { 
            inherit pkgs; 
            cmake-nix-rules = { 
              mkModule = args: args; 
              mkLibrary = args: args; 
              mkExecutable = args: args; 
            }; 
          };
        in moduleNix.dependencies or [];
      
      # Build adjacency list representation
      graph = builtins.listToAttrs (map (moduleInfo: {
        name = moduleInfo.name;
        value = {
          info = moduleInfo;
          deps = getDependencies moduleInfo;
        };
      }) modules);
      
      # Kahn's algorithm for topological sorting
      kahn = graph: visited: result:
        let
          # Find nodes with no dependencies (empty deps list)
          noDependencies = lib.filter (name: 
            let node = graph.${name}; in
            node.deps == []
          ) (lib.attrNames graph);
          availableNodes = lib.filter (name: !(lib.elem name visited)) noDependencies;
        in
        if availableNodes == [] then
          if (lib.length (lib.attrNames graph)) == (lib.length visited) then
            result  # Successfully sorted
          else
            throw "Circular dependency detected in modules: ${lib.concatStringsSep ", " (lib.attrNames (lib.filterAttrs (n: v: !(lib.elem n visited)) graph))}"
        else
          let
            nextNode = lib.head availableNodes;
            newVisited = visited ++ [ nextNode ];
            newResult = result ++ [ graph.${nextNode}.info ];
            # Remove the processed node from dependency lists of remaining nodes
            newGraph = lib.mapAttrs (name: node: 
              if name == nextNode then 
                node  # Keep the processed node for now
              else 
                node // { deps = lib.filter (dep: dep != nextNode) node.deps; }
            ) graph;
          in kahn newGraph newVisited newResult;
    in
    kahn graph [] [];
  
  # Resolve module dependencies by building them in dependency order
  resolveModuleDependencies = modules: pkgs: cmake-rules:
    let
      # Use the topological sort function defined in this same rec set
      sortedModules = topologicalSort modules;
      
      # Build modules in dependency order
      buildModules = moduleInfos: builtModules:
        if moduleInfos == [] then 
          builtModules
        else
          let
            moduleInfo = lib.head moduleInfos;
            moduleNix = import moduleInfo.nixFile { 
              inherit pkgs; 
              cmake-nix-rules = cmake-rules; 
            };
            
            # Get dependencies for this module
            moduleDeps = moduleNix.passthru.moduleDependencies or [];
            
            # Resolve internal dependencies to built modules
            resolvedDeps = map (depName:
              if builtModules ? ${depName} then
                builtModules.${depName}
              else
                throw "Module '${moduleInfo.name}' depends on '${depName}' which hasn't been built yet"
            ) moduleDeps;
            
            # Build this module with resolved dependencies
            # Create a modified cmake-rules that includes resolved dependencies
            moduleSpecificRules = cmake-rules // {
              mkModule = args: cmake-rules.mkModule (args // {
                internalDeps = resolvedDeps;
              });
            };
            
            builtModule = import moduleInfo.nixFile { 
              inherit pkgs; 
              cmake-nix-rules = moduleSpecificRules; 
            };
            
            newBuiltModules = builtModules // { ${moduleInfo.name} = builtModule; };
          in
          buildModules (lib.tail moduleInfos) newBuiltModules;
    in
    buildModules sortedModules {};
}
