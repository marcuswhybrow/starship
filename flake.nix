{
  description = "Starship terminal prompt configured by Marcus";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = inputs: let
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    tomlFormat = pkgs.formats.toml {};
    configFile = tomlFormat.generate "starship.toml" {
      nix_shell = {
        heuristic = true; 
      };
    };

    wrapper = pkgs.runCommand "starship-wrapper" {
      nativeBuildInputs = [ pkgs.makeWrapper ];
    } ''
      mkdir --parents $out/bin
      makeWrapper ${pkgs.starship}/bin/starship $out/bin/starship \
        --set STARSHIP_CONFIG ${configFile}
    '';

    fishInit = pkgs.writeTextDir "share/fish/vendor_conf.d/starship.fish" ''
      if status is-interactive
        ${wrapper}/bin/starship init fish | source
      end
    '';
  in {

    packages.x86_64-linux.starship = pkgs.symlinkJoin {
      name = "starship";
      paths = [ 
        wrapper # first ./bin/starship takes precedence
        pkgs.starship 
        fishInit 
      ]; 
    };

    packages.x86_64-linux.default = inputs.self.packages.x86_64-linux.starship;
  };
}
