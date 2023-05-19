{ pkgs ? import <nixpkgs> { } }:
with pkgs;
mkShell {
  buildInputs = with pkgs; [
    deno
    elmPackages.elm-format
    elmPackages.elm-language-server
    nodejs-16_x
    nodePackages.pnpm
  ];
}
