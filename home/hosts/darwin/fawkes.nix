{config, ...}: let
  protonDrive = "${config.home.homeDirectory}/Library/CloudStorage/ProtonDrive-max@knerrich.com-folder";
  protonDriveLink = name: config.lib.file.mkOutOfStoreSymlink "${protonDrive}/${name}";
in {
  imports = [
    ../../darwin
    ../../base/tui/pi.nix
  ];

  home.file = {
    "[2] - Personal".source = protonDriveLink "[2] - Personal";
    "[3] - Work".source = protonDriveLink "[3] - Work";
    "[4] - Money & Tax".source = protonDriveLink "[4] - Money & Tax";
    "[9] - ARCHIVE".source = protonDriveLink "[9] - ARCHIVE";
  };
}
