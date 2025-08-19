# Tests for internal dependency resolution
{ pkgs, cmake-rules, testUtils }:

let
  inherit (testUtils) assertEqual;

in [
  {
    name = "simple-test";
    fn = _: true;
  }
]