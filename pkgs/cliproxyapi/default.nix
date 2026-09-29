# CLIProxyAPI: one OpenAI/Claude/Codex-compatible endpoint in front of the
# coding subscriptions, with provider sign-ins and usage statistics. Not in
# nixpkgs; this is upstream's static linux_amd64 release binary. The
# no-plugin build is statically linked, and plugins stay disabled anyway.
{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "cliproxyapi";
  version = "8.0.3";

  src = fetchurl {
    url = "https://github.com/router-for-me/CLIProxyAPI/releases/download/v${finalAttrs.version}/CLIProxyAPI_${finalAttrs.version}_linux_amd64_no-plugin.tar.gz";
    hash = "sha256-m+JmIACaZtKBtwEN1u4/k1bde0W2mC8EUeAdaY+KT8E=";
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 cli-proxy-api $out/bin/cliproxyapi
    runHook postInstall
  '';

  meta = {
    description = "Proxy exposing coding-agent subscriptions as an OpenAI/Claude/Codex-compatible API";
    homepage = "https://github.com/router-for-me/CLIProxyAPI";
    license = lib.licenses.mit;
    mainProgram = "cliproxyapi";
    platforms = ["x86_64-linux"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
})
