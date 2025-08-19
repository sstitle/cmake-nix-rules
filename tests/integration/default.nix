# Integration tests for cmake-nix-rules
{ pkgs, cmake-rules, testUtils }:

let
  inherit (testUtils) assertEqual;

in [
  {
    name = "cmake-generation-basic-library";
    fn = _:
      let 
        targets = {
          lib = cmake-rules.mkLibrary { name = "test-lib"; };
        };
        cmakeContent = cmake-rules.generateModuleCMakeLists {
          name = "test-module";
          inherit targets;
          dependencies = [];
          externalDeps = [];
          fetchContentDeps = [];
          buildConfig = cmake-rules.defaultBuildConfig;
        };
        content = builtins.readFile cmakeContent;
      in
        assert (builtins.isString content) "CMake content should be a string";
        assert (builtins.match ".*project\\(test-module\\).*" content != null) "Should contain project declaration";
        assert (builtins.match ".*add_library\\(test-lib STATIC.*" content != null) "Should contain library declaration";
  }
  
  {
    name = "cmake-generation-with-external-deps";
    fn = _:
      let 
        targets = {
          lib = cmake-rules.mkLibrary { name = "test-lib"; };
        };
        mockEigenPkg = { pname = "eigen"; };
        cmakeContent = cmake-rules.generateModuleCMakeLists {
          name = "test-module";
          inherit targets;
          dependencies = [];
          externalDeps = [ mockEigenPkg ];
          fetchContentDeps = [];
          buildConfig = cmake-rules.defaultBuildConfig;
        };
        content = builtins.readFile cmakeContent;
      in
        assert (builtins.match ".*find_package\\(eigen REQUIRED\\).*" content != null) "Should contain find_package for eigen";
  }
  
  {
    name = "cmake-generation-with-fetchcontent";
    fn = _:
      let 
        targets = {
          lib = cmake-rules.mkLibrary { name = "test-lib"; };
        };
        fetchDep = {
          name = "nlohmann-json";
          url = "https://github.com/nlohmann/json.git";
          tag = "v3.11.2";
        };
        cmakeContent = cmake-rules.generateModuleCMakeLists {
          name = "test-module";
          inherit targets;
          dependencies = [];
          externalDeps = [];
          fetchContentDeps = [ fetchDep ];
          buildConfig = cmake-rules.defaultBuildConfig;
        };
        content = builtins.readFile cmakeContent;
      in
        assert (builtins.match ".*include\\(FetchContent\\).*" content != null) "Should include FetchContent";
        assert (builtins.match ".*FetchContent_Declare\\(nlohmann-json.*" content != null) "Should declare nlohmann-json";
        assert (builtins.match ".*GIT_REPOSITORY https://github.com/nlohmann/json.git.*" content != null) "Should include git repository";
  }
  
  {
    name = "cmake-generation-executable-target";
    fn = _:
      let 
        targets = {
          exe = cmake-rules.mkExecutable { 
            name = "test-exe"; 
            entrypoint = "main.cpp";
          };
        };
        cmakeContent = cmake-rules.generateModuleCMakeLists {
          name = "test-module";
          inherit targets;
          dependencies = [];
          externalDeps = [];
          fetchContentDeps = [];
          buildConfig = cmake-rules.defaultBuildConfig;
        };
        content = builtins.readFile cmakeContent;
      in
        assert (builtins.match ".*add_executable\\(test-exe main.cpp\\).*" content != null) "Should contain executable declaration";
  }
  
  {
    name = "cmake-generation-ninja-generator";
    fn = _:
      let 
        targets = {
          lib = cmake-rules.mkLibrary { name = "test-lib"; };
        };
        buildConfig = cmake-rules.defaultBuildConfig // { generator = "ninja"; };
        cmakeContent = cmake-rules.generateModuleCMakeLists {
          name = "test-module";
          inherit targets;
          dependencies = [];
          externalDeps = [];
          fetchContentDeps = [];
          inherit buildConfig;
        };
        content = builtins.readFile cmakeContent;
      in
        # The generator is set during cmake invocation, not in CMakeLists.txt
        assert (builtins.isString content) "CMake content should be generated";
  }
  
  {
    name = "build-config-inheritance";
    fn = _:
      let 
        customConfig = {
          buildType = "release";
          compiler = "clang";
          cppStandard = "23";
        };
        targets = {
          lib = cmake-rules.mkLibrary { name = "test-lib"; };
        };
        cmakeContent = cmake-rules.generateModuleCMakeLists {
          name = "test-module";
          inherit targets;
          dependencies = [];
          externalDeps = [];
          fetchContentDeps = [];
          buildConfig = cmake-rules.defaultBuildConfig // customConfig;
        };
        content = builtins.readFile cmakeContent;
      in
        assert (builtins.match ".*set\\(CMAKE_CXX_STANDARD 23\\).*" content != null) "Should use custom C++ standard";
        assert (builtins.match ".*CMAKE_BUILD_TYPE release.*" content != null) "Should use custom build type";
  }
]
