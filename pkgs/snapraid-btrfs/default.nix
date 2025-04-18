{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  coreutils,
  gnugrep,
  gawk,
  gnused,
  snapraid,
  snapper,
}:
stdenv.mkDerivation rec {
  pname = "snapraid-btrfs";
  version = "0.1.0"; # Adding a version field, adjust as needed

  # used fork as original repo seem no longer maintained
  # and this fork works with snapper v11
  src = fetchFromGitHub {
    owner = "D34DC3N73R";
    repo = "snapraid-btrfs";
    rev = "a43e9a40773772b881b1450edfef28c9937f5f27";
    hash = "sha256-zOFc1/H2hgcZMeGUnLvuWL+SFvE5kvekm0F/dvhakWI=";
  };

  # No build phase needed as this is a shell script
  dontBuild = true;

  nativeBuildInputs = [makeWrapper];

  runtimeDependencies = [
    coreutils
    gnugrep
    gawk
    gnused
    snapraid
    snapper
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp snapraid-btrfs $out/bin/
    chmod +x $out/bin/snapraid-btrfs
    patchShebangs $out/bin/snapraid-btrfs

    wrapProgram $out/bin/snapraid-btrfs \
      --prefix PATH : ${lib.makeBinPath runtimeDependencies}

    runHook postInstall
  '';

  meta = with lib; {
    description = "A wrapper script to ease using snapraid with btrfs snapshots";
    homepage = "https://github.com/D34DC3N73R/snapraid-btrfs";
    license = licenses.gpl3; # Assuming GPL-3.0 license, adjust if different
    maintainers = []; # Add yourself if you want
    platforms = platforms.linux;
    mainProgram = "snapraid-btrfs";
  };
}
