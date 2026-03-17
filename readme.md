Original source: https://tech.leeporte.co.uk/dell-1320c-on-ubuntu-18-04/

run install.sh as root

Use the Ubuntu Printers dialog, choose "Add Printer" then wait for it to populate the list, then choose the printer from "Discovered network printers". Then on the next page it should recommend the correct driver.

Original instructions: add the printer with the ppd at https://localhost:631

# Arch

Since this printer works with the drivers for Fuji Xerox DocuPrint C525 A you can use the Arch package for that as a starting point, see this thread:

https://forum.manjaro.org/t/having-trouble-installing-xerox-c525a/29042

However if you use the install process above it should work as long as you enable (Multilib)[https://wiki.archlinux.org/title/official_repositories#Enabling_multilib] and install lib32-libcups.

# NixOS

NixOS requires special handling because it doesn't follow the traditional Linux filesystem hierarchy. This repo provides a Nix flake and NixOS module for easy installation.

## Option 1: NixOS Module (Recommended)

Add the flake to your `flake.nix` inputs and enable the module in your NixOS configuration:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    dell-1320c.url = "github:colinramsay/dell1320c-linux";
  };

  outputs = { self, nixpkgs, dell-1320c, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        dell-1320c.nixosModules.dell-1320c
        {
          services.printing.drivers.dell-1320c.enable = true;
        }
      ];
    };
  };
}
```

Then rebuild your system:

```sh
sudo nixos-rebuild switch
```

The printer will be available in CUPS. Add it via the CUPS web interface at https://localhost:631 or using `lpadmin`.

## Option 2: Package Only

If you prefer to manage CUPS configuration yourself, you can add just the driver package:

```nix
# In your NixOS configuration
{ pkgs, ... }:

let
  dell-1320c-driver = (builtins.getFlake "github:colinramsay/dell1320c-linux").packages.${pkgs.system}.dell-1320c-driver;
in
{
  services.printing.enable = true;
  services.printing.drivers = [ dell-1320c-driver ];
}
```

## Adding the Printer

After rebuilding, add the printer via CUPS:

1. Open https://localhost:631 in your browser
2. Go to Administration > Add Printer
3. Select your Dell 1320c from the discovered printers (or enter its IP/URI)
4. Choose "Dell 1320C" from the driver list

Or via the command line:

```sh
# For a network printer (replace IP_ADDRESS with your printer's IP)
lpadmin -p Dell-1320c -E -v socket://IP_ADDRESS:9100 -m dell/en/dell-1320c.ppd
```

## Notes

- The driver uses proprietary 32-bit Fuji Xerox filter binaries. The Nix package automatically patches these to work on NixOS.
- Ghostscript is required and is automatically included as a dependency.
- This driver is also compatible with the Fuji Xerox DocuPrint C525 A printer.
