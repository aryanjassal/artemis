{
  description = ''"Trust me bro, 16 bits is enough"'';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          name = "artemis";
          buildInputs = with pkgs; [ gnumake nasm asm-lsp bochs ];
        };
      });
}
