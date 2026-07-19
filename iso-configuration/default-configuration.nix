{ lib, pkgs, ... }:

{
  imports = [
    ./apple-silicon-support
    ./hardware-configuration.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = false;
  };

  boot.postBootCommands = ''
    for o in $(</proc/cmdline); do
      case "$o" in
        live.nixos.passwd=*)
          set -- $(IFS==; echo $o)
          echo "nixos:$2" | ${pkgs.shadow}/bin/chpasswd
          ;;
      esac
    done

    echo Extracting Asahi firmware...
    mkdir -p /tmp/.fwsetup/{esp,extracted}

    mount /dev/disk/by-partuuid/`cat /proc/device-tree/chosen/asahi,efi-system-partition` /tmp/.fwsetup/esp
    ${pkgs.asahi-fwextract}/bin/asahi-fwextract /tmp/.fwsetup/esp/asahi /tmp/.fwsetup/extracted
    umount /tmp/.fwsetup/esp

    pushd /tmp/.fwsetup/
    cat /tmp/.fwsetup/extracted/firmware.cpio | ${pkgs.cpio}/bin/cpio -id --quiet --no-absolute-filenames
    mkdir -p /lib/firmware
    mv vendorfw/* /lib/firmware
    popd
    rm -rf /tmp/.fwsetup
  '';

  environment.systemPackages = with pkgs; [
    asahi-bless
    git
    gh
    ripgrep
    micro
  ];

  hardware.asahi.enable = true;

  networking = {
    wireless.enable = false;
    wireless.iwd.enable = true;
    networkmanager.wifi.backend = "iwd";
  };

  nix.settings = {
    warn-dirty = false;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  system.stateVersion = lib.versions.majorMinor lib.version;

  users.users.qeden = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };
}
