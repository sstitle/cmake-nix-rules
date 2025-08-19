# Tests for external dependency handling
{ pkgs, cmake-rules, testUtils }:

let
  inherit (testUtils) assertEqual;

in [
  {
    name = "external-deps-simple-format";
    fn = _:
      let 
        targets = {
          lib = cmake-rules.mkLibrary { name = "test-lib"; };
        };
        mockPkg = { pname = "spdlog"; };
        cmakeContent = cmake-rules.generateModuleCMakeLists {
          name = "test-module";
          inherit targets;
          dependencies = [];
          externalDeps = [ mockPkg ];
          fetchContentDeps = [];
          buildConfig = cmake-rules.defaultBuildConfig;
        };
        content = builtins.readFile cmakeContent;
      in
        assert (builtins.match ".*find_package\\(spdlog REQUIRED\\).*" content != null) "Should use package pname for simple format";
        assert (builtins.match ".*target_link_libraries\\(test-lib spdlog::spdlog\\).*" content != null) "Should use common target pattern for simple format";
        true;
  }
  
  {
    name = "external-deps-detailed-format";
    fn = _:
      let 
        targets = {
          lib = cmake-rules.mkLibrary { name = "test-lib"; };
        };
        eigenDep = { 
          pkg = { pname = "eigen"; }; 
          cmake.package = "Eigen3"; 
          cmake.targets = ["Eigen3::Eigen"]; 
        };
        cmakeContent = cmake-rules.generateModuleCMakeLists {
          name = "test-module";
          inherit targets;
          dependencies = [];
          externalDeps = [ eigenDep ];
          fetchContentDeps = [];
          buildConfig = cmake-rules.defaultBuildConfig;
        };
        content = builtins.readFile cmakeContent;
      in
        assert (builtins.match ".*find_package\\(Eigen3 REQUIRED\\).*" content != null) "Should use specified cmake package name";
        assert (builtins.match ".*target_link_libraries\\(test-lib Eigen3::Eigen\\).*" content != null) "Should use specified cmake target";
        true;
  }
  
  {
    name = "external-deps-multiple-targets";
    fn = _:
      let 
        targets = {
          lib = cmake-rules.mkLibrary { name = "test-lib"; };
        };
        boostDep = { 
          pkg = { pname = "boost"; }; 
          cmake.package = "Boost"; 
          cmake.targets = ["Boost::system" "Boost::filesystem"]; 
        };
        cmakeContent = cmake-rules.generateModuleCMakeLists {
          name = "test-module";
          inherit targets;
          dependencies = [];
          externalDeps = [ boostDep ];
          fetchContentDeps = [];
          buildConfig = cmake-rules.defaultBuildConfig;
        };
        content = builtins.readFile cmakeContent;
      in
        assert (builtins.match ".*find_package\\(Boost REQUIRED\\).*" content != null) "Should use specified cmake package name";
        assert (builtins.match ".*target_link_libraries\\(test-lib Boost::system\\).*" content != null) "Should link first target";
        assert (builtins.match ".*target_link_libraries\\(test-lib Boost::filesystem\\).*" content != null) "Should link second target";
        true;
  }
  
  {
    name = "external-deps-mixed-formats";
    fn = _:
      let 
        targets = {
          lib = cmake-rules.mkLibrary { name = "test-lib"; };
        };
        mixedDeps = [
          { pname = "spdlog"; }  # Simple format
          { pkg = { pname = "eigen"; }; cmake.package = "Eigen3"; cmake.targets = ["Eigen3::Eigen"]; }  # Detailed
        ];
        cmakeContent = cmake-rules.generateModuleCMakeLists {
          name = "test-module";
          inherit targets;
          dependencies = [];
          externalDeps = mixedDeps;
          fetchContentDeps = [];
          buildConfig = cmake-rules.defaultBuildConfig;
        };
        content = builtins.readFile cmakeContent;
      in
        assert (builtins.match ".*find_package\\(spdlog REQUIRED\\).*" content != null) "Should handle simple format";
        assert (builtins.match ".*find_package\\(Eigen3 REQUIRED\\).*" content != null) "Should handle detailed format";
        assert (builtins.match ".*target_link_libraries\\(test-lib spdlog::spdlog\\).*" content != null) "Should link simple format correctly";
        assert (builtins.match ".*target_link_libraries\\(test-lib Eigen3::Eigen\\).*" content != null) "Should link detailed format correctly";
        true;
  }
  
  {
    name = "build-inputs-extraction";
    fn = _:
      let 
        mockSpdlog = { pname = "spdlog"; };
        mockEigen = { pname = "eigen"; };
        mixedDeps = [
          mockSpdlog  # Simple format
          { pkg = mockEigen; cmake.package = "Eigen3"; }  # Detailed format
        ];
        extractedPkgs = map (dep: 
          if builtins.isAttrs dep && dep ? pkg 
          then dep.pkg 
          else dep
        ) mixedDeps;
        result1 = assertEqual 2 (builtins.length extractedPkgs) "Should extract both packages";
        result2 = assertEqual mockSpdlog (builtins.head extractedPkgs) "Should extract simple format package";
        result3 = assertEqual mockEigen (builtins.elemAt extractedPkgs 1) "Should extract detailed format package";
      in
        if result1 == "PASS Should extract both packages" &&
           result2 == "PASS Should extract simple format package" &&
           result3 == "PASS Should extract detailed format package"
        then "PASS: build inputs extraction works correctly"
        else throw "One or more build inputs extraction assertions failed";
  }
]
