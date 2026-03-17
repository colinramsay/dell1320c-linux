{ lib
, stdenv
, ghostscript
, patchelf
, pkgsi686Linux
}:

let
  cups32 = pkgsi686Linux.cups.lib;
  glibc32 = pkgsi686Linux.glibc;
  interpreter32 = "${glibc32}/lib/ld-linux.so.2";
in
stdenv.mkDerivation {
  pname = "dell-1320c-driver";
  version = "1.0";

  src = lib.cleanSource ./..;

  nativeBuildInputs = [
    patchelf
  ];

  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall

    # Install filter binaries
    mkdir -p $out/lib/cups/filter

    # Copy and patch all 32-bit binary filters
    for f in usr/lib/cups/filter/FXM_*; do
      name=$(basename "$f")
      if [ "$name" = "FXM_PS2PM" ]; then
        continue  # handle the shell script separately
      fi
      cp "$f" "$out/lib/cups/filter/$name"
      chmod +x "$out/lib/cups/filter/$name"
      patchelf \
        --set-interpreter "${interpreter32}" \
        --set-rpath "${lib.makeLibraryPath [ cups32 glibc32 ]}" \
        "$out/lib/cups/filter/$name"
    done

    # Install FXM_PS2PM shell script with ghostscript on PATH
    # Rewrite it to use the correct ghostscript path
    substitute usr/lib/cups/filter/FXM_PS2PM $out/lib/cups/filter/FXM_PS2PM \
      --replace-fail 'prefix=/usr' 'prefix=${ghostscript}' \
      --replace-fail 'exec_prefix=''${prefix}' 'exec_prefix=${ghostscript}'
    chmod +x $out/lib/cups/filter/FXM_PS2PM

    # Install DLUT color lookup table
    mkdir -p $out/share/cups/dell/dlut
    cp usr/share/cups/dell/dlut/dell-1320c.dlut $out/share/cups/dell/dlut/

    # Install PPD file with paths adjusted for Nix store
    mkdir -p $out/share/cups/model/dell/en
    substitute dell-1320c.ppd $out/share/cups/model/dell/en/dell-1320c.ppd \
      --replace-fail '/usr/lib/cups/filter/FXM_PF' "$out/lib/cups/filter/FXM_PF" \
      --replace-fail '/usr/lib/cups/filter/FXM_MF' "$out/lib/cups/filter/FXM_MF" \
      --replace-fail '*FXFilterDir: "/usr/lib/cups/filter"' "*FXFilterDir: \"$out/lib/cups/filter\"" \
      --replace-fail '/usr/share/cups/dell/dlut/dell-1320c.dlut' "$out/share/cups/dell/dlut/dell-1320c.dlut"

    runHook postInstall
  '';

  meta = with lib; {
    description = "CUPS driver for the Dell 1320c color laser printer";
    longDescription = ''
      Proprietary Fuji Xerox filter binaries packaged for use with CUPS
      on NixOS. Also compatible with the Fuji Xerox DocuPrint C525 A.
    '';
    license = licenses.unfree;
    platforms = [ "x86_64-linux" "i686-linux" ];
    maintainers = [];
  };
}
