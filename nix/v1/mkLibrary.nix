# mkLibrary function for creating library targets
{ pkgs }:

{ name
, type ? "static"  # "static" | "dynamic"
}:

{
  inherit name type;
  targetType = "library";
  
  # Validate library type
  __checkType = 
    if (type != "static" && type != "dynamic") 
    then throw "Library type must be 'static' or 'dynamic', got: ${type}"
    else true;
}
