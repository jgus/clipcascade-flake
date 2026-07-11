{
  description = "ClipCascade server: self-hosted, end-to-end-encrypted clipboard sync (Sathvik-Rao/ClipCascade).";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-lib = {
      url = "github:jgus/flake-lib/v1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, flake-lib }:
    let
      jdkVersion = 21;
      pin = import ./pin.nix;
      inherit (pin) version;
      source = {
        type = "github-release-asset";
        owner = "Sathvik-Rao";
        repo = "ClipCascade";
        asset = "ClipCascade-Server-JRE_${toString jdkVersion}.jar";
        # Release tags are unprefixed (3.2.0), overriding flake-lib's default v${version}.
        tag = "\${version}";
      };
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        jdk = pkgs."jdk${toString jdkVersion}_headless";

        src = pkgs.fetchurl {
          url = "https://github.com/${source.owner}/${source.repo}/releases/download/${version}/${source.asset}";
          hash = pin.hash or "";
        };

        clipcascade-server = pkgs.stdenvNoCC.mkDerivation {
          pname = "clipcascade-server";
          inherit version src;

          nativeBuildInputs = [ pkgs.makeWrapper ];
          dontUnpack = true;

          buildPhase = ''
            runHook preBuild

            makeWrapper ${jdk}/bin/java $out/bin/clipcascade-server \
              --add-flags "-jar $src"

            runHook postBuild
          '';

          meta = {
            description = "Self-hosted, end-to-end-encrypted clipboard sync server";
            homepage = "https://github.com/Sathvik-Rao/ClipCascade";
            platforms = jdk.meta.platforms;
            mainProgram = "clipcascade-server";
          };
        };
      in
      {
        packages = {
          inherit clipcascade-server;
          default = clipcascade-server;
          update-version = flake-lib.lib.mkUpdateVersion {
            inherit pkgs source;
            buildAttr = "clipcascade-server";
          };
          update-branches = flake-lib.lib.mkUpdateBranches {
            inherit pkgs source;
            pinSchema = "github-asset";
          };
        };
      });
}
