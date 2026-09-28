# CLIProxyAPI: one OpenAI/Claude/Codex-compatible endpoint in front of the
# coding subscriptions, with provider sign-ins and usage statistics. Not in
# nixpkgs.
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule (finalAttrs: {
  pname = "cliproxyapi";
  version = "8.0.3";

  src = fetchFromGitHub {
    owner = "router-for-me";
    repo = "CLIProxyAPI";
    tag = "v${finalAttrs.version}";
    hash = "sha256-1LrRpPkteIzBpwIdxFpA9WupwryRBoVt4jO/T8Dzgng=";
  };

  vendorHash = "sha256-r3yWkdMcM40G9jV7MxW/qNv3E9WrHavFilW24quEf+8=";

  subPackages = ["cmd/server"];
  ldflags = [
    "-s"
    "-w"
    "-X main.Version=${finalAttrs.version}"
  ];

  # Upstream tests reach provider APIs.
  doCheck = false;

  postInstall = ''
    mv $out/bin/server $out/bin/cliproxyapi
  '';

  meta = {
    description = "Proxy exposing coding-agent subscriptions as an OpenAI/Claude/Codex-compatible API";
    homepage = "https://github.com/router-for-me/CLIProxyAPI";
    license = lib.licenses.mit;
    mainProgram = "cliproxyapi";
    platforms = lib.platforms.linux;
  };
})
