# SSHRD Lite

* A lite fork of [SSH RAMDISK Script](https://github.com/verygenericname/SSHRD_Script)

## Features

1. Make SSH ramdisk without connecting the iDevice.
2. Lite version which only focuses to make SSH ramdisk and not like main fork.
3. Other features you should find it yourself :).

## Supported devices and limits

* Windows users you need to get bash environment. You can get it by installing MSYS2, Cygwin, or Git-Bash
* Linux and macOS users you already have bash environment.
* A 64-bit iDevice supported by checkm8 (A7-A11).
* Apple TV and M1/T2 requires manually replacing the "ssh.tar.gz" find it [here](https://github.com/verygenericname/sshtars).
* Linux/Windows currently doesn't support making ramdisk for iOS 16.1 and above.

## Preparing for installtion

**Windows users:**
1. Install [MSYS2](https://www.msys2.org)
2. Install git: `pacman -S git`
3. Clone this repo and run.

**Linux users:**
1. Update packages list: `sudo apt-get update`
2. Install git: `sudo apt install git`
3. Clone this repo and run.

**macOS users:**
1. Install [brew](https://brew.sh)
2. Install git: `brew install git`
3. Clone this repo and run.

**Clone this repo**
```shell
git clone --recurse-submodules 'https://github.com/mast3rz3ro/SSHRD_Script_Lite' && chmod +x './SSHRD_Script_Lite/sshrd_lite.sh'
```

## How to run

**Please note that the same exact commands can be used on all platforms.**

```shell
# Getting started
$ cd 'SSHRD_Script_Lite' # enter into working dir.
$ ./sshrd_lite.sh -h # print help info

### Some live examples ###

# make ramdisk for product type 'iphone8,2' with latest ios 15 available
$ './sshrd_lite.sh' -p 'iphone8,2' -s '15'

# make ramdisk for product type 'iphone8,2' with exact ios version.
$ './sshrd_lite.sh' -p 'iphone8,2' -s '15.7.9'

# make ramdisk for product type 'iphone8,2' with exact build version.
$ './sshrd_lite.sh' -p 'iphone8,2' -b '19H384'


### Extra options ###

# decrypt iboot files with gaster useful in case firmware keys not available yet.
$ './sshrd_lite.sh' -p 'iphone8,2' -b '19H384' -g

# repack only ramdisk.img image using img4tool
$ './sshrd_lite.sh' -p 'iphone8,2' -b '19H384' -z 2

# force patch iboot files using kairos
$ './sshrd_lite.sh' -p 'iphone8,2' -b '19H384' -y 1 # (if not used script will auto select best for you)

# force patch iboot files using iBoot64Patcher # (if not used script will auto select best for you)
$ './sshrd_lite.sh' -p 'iphone8,2' -b '19H384' -y 2

# connect device via ssh mode (used after sshrd booted)
$ './sshrd_lite.sh' -c
```


## Important Notes

* Do not run 'mount_filesystems' if you are running on iOS 11.x and lower.

* On Linux, usbmuxd will have to be restarted. On most distros, it's as simple as these 2 commands in another terminal:

```
$ sudo systemctl stop usbmuxd
$ sudo usbmuxd -p -f
```

* The original sshtars can be found [here](https://github.com/verygenericname/sshtars)

* For support please open new issue [here](https://github.com/mast3rz3ro/sshrd_script_lite/issues)

* r/setupapp memebers don't miss the chance to join [here](https://t.me/Tsun4m1_tool)


## Credits

- [verygenericname](https://github.com/verygenericname/SSHRD_Script) The author of SSHRD Script
- [ifirmparser](https://github.com/mast3rz3ro/ifirmware_parser) for preparing boot files and decryption keys
- [TRANTUAN](https://github.com/TRANTUAN-PC) for testing, thanks you so much :)
- [kairos](https://github.com/dayt0n/kairos) iboot files patcher (supports patching the newer iOS e.g iOS 17.1)
- [firecore](https://github.com/firecore/Seas0nPass-Windows/) for providing an updated hfsplus for windows
- [tihmstar](https://github.com/tihmstar) for pzb/original iBoot64Patcher/img4tool
- [xerub](https://github.com/xerub) for img4lib and restored_external in the ramdisk
- [Cryptic](https://github.com/Cryptiiiic) for iBoot64Patcher fork
- [Nebula](https://github.com/itsnebulalol) for a bunch of QOL fixes to this script
- [OpenAI](https://chat.openai.com/chat) for converting [kerneldiff](https://github.com/mcg29/kerneldiff) into [C](https://github.com/verygenericname/kerneldiff_C)
- [Ploosh](https://github.com/plooshi) for KPlooshFinder a modern kernel patcher
- [libirecovery](https://github.com/libimobiledevice/libimobiledevice) for the irecovery utility
- [gaster](https://github.com/0x7ff/gaster) Another fork of checkm8 used to pwn dfu the device
- [sshrd_tools](https://github.com/mast3rz3ro/sshrd_tools) precompiled tools for all platforms
