# mkExecutable function for creating executable targets
{ pkgs }:

{ name
, entrypoint
, sources ? []
}:

{
  inherit name entrypoint sources;
  targetType = "executable";
  
  # Validate entrypoint exists (we'll validate at build time)
  __checkEntrypoint = 
    if (entrypoint == null || entrypoint == "")
    then throw "Executable entrypoint cannot be null or empty"
    else true;
}
