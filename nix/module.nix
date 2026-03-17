flake:

{ config, lib, pkgs, ... }:

let
  cfg = config.services.dell-1320c;
  driverPkg = flake.packages.${pkgs.stdenv.hostPlatform.system}.dell-1320c-driver;
in
{
  options.services.dell-1320c = {
    enable = lib.mkEnableOption "Dell 1320c printer driver";
  };

  config = lib.mkIf cfg.enable {
    # Enable CUPS
    services.printing.enable = true;

    # Add the driver package so CUPS can find the PPD and filters
    services.printing.drivers = [ driverPkg ];
  };
}
