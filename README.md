# SSHRD Lite

* A lite fork of [SSH RAMDISK Script](https://github.com/verygenericname/SSHRD_Script)

## Features

1. Make SSH ramdisk without connecting the iDevice.
2. Lite version which only focuses to make SSH ramdisk and not like main fork.
3. Other features you should find it yourself :).

## Requirements

* Windows users you need to get bash environment. You can get it by installing MSYS2, Cygwin, or Git-Bash
* Linux and MacOS users you already have bash environment.

## Supported devices and limits

* A 64-bit iDevice supported by checkm8 (A7-A11).
* Apple TV and M1/T2 requires manually replacing the "ssh.tar.gz" find it [here](https://github.com/verygenericname/sshtars).
* Linux/Windows currently doesn't support making ramdisk for iOS 16.1 and above.

## How to use (All Platforms):

1. You need to install git:

```
For MSYS2 users you can install git via:
$ pacman -S git
```

2. If you already have git then the reset of steps are same:

```
$ git clone --recurse-submodules 'https://github.com/mast3rz3ro/SSHRD_Script_Lite'
$ cd SSHRD_Script_Lite
$ chmod +x ./sshrd_lite.sh
$ ./sshrd_lite.sh -h
```

* Then run it like below:

```
$ ./sshrd_lite.sh -p product_name -s ios_version
or
$ ./sshrd_lite.sh -p product_name -b build_version
```

* For more info see:
```
$ ./sshrd_lite.sh -h
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

* If you are a member of subreddit/setupapp then you should join [here](https://t.me/Tsun4m1_tool)


## Credits

- [verygenericname](https://github.com/verygenericname/SSHRD_Script) The author of SSHRD Script
- [ifirmparser](https://github.com/mast3rz3ro/ifirmware_parser) for preparing boot files and decryption keys
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
