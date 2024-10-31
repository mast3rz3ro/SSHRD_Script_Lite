#!/usr/bin/env bash


if [ "$1" = '' ]; then echo "For info please use 'sshrd_lite.sh -h'"; exit; fi
usage (){
		echo '[-] Usage: sshrd_lite.sh [parameters]'
		echo '[-] Basic Parameters |      Optional'
		echo '----------------------------------------'
		echo ' -p Product Name     | -m specify model version'
		echo ' -s iOS Version      | -g decrypt with gaster'
		echo ' -b Build Version    | -y 1/2 kairos/iBoot64Patcher'
		echo ' -c SSH connection   | -z 1/2 img4/img4tool'
		echo '----------------------------------------'
		echo '[-] For more info see "ifirmware_parser.sh -h"'
		exit 1
}

		##############################
		#       Initialization       #
		##############################

if [ ! -s 'misc/platform_check.sh' ] || [ ! -s './ifirmware_parser.sh' ]; then
	if [ -s './ifirmware_parser/README.md' ]; then
		echo '[-] Setting-up ifirmware parser (for first run) ...'
		cp -f './ifirmware_parser/ifirmware_parser.sh' './'
		cp -f './ifirmware_parser/ca-bundle.crt' './'
		cp -f './ifirmware_parser/misc/platform_check.sh' './misc/platform_check.sh'
		cp -f './ifirmware_parser/misc/firmwares.json' './misc/firmwares.json'
	else
		echo '[!] Required module are missing ...'
		echo '[!] Downloading ifirmware parser module ...'
		echo '[!] Submodule link: https://github.com/mast3rz3ro/ifirmware_parser'
		git submodule update --init
		exit 1
	fi
fi

		source './misc/platform_check.sh' # Check platform and set tools
		
		chmod -R +x 'tools/'
		chmod +x './ifirmware_parser.sh' './misc/platform_check.sh' './boot_sshrd.sh'

		########## Switch loop ##########
while getopts p:m:s:b:y:z:cgh option;
	do
		case "${option}"
	in
		p) args+=(-p "${OPTARG}" );;
		m) args+=(-m "${OPTARG}" );;
		s) args+=(-s "${OPTARG}" );;
		b) args+=(-b "${OPTARG}" );;
		y) patch_iboot_with="${OPTARG}";;
		z) pack_ramdisk_with="${OPTARG}";;
		# Options
		c) ssh_connect="yes";;
		g) pwndfu_decrypt="yes";;
		h) usage;; # call function
	esac
done
	

if [ "$ssh_connect" = 'yes' ]; then
		if [ "$iproxy" = '' ]; then echo '[!] Warnning iproxy variable are not set !'; fi
		if [ "$sshpass" = '' ]; then echo '[!] Warnning sshpass variable are not set !'; fi
		sudo "$iproxy" 2222 22 &>/dev/null &
		check=$("$sshpass" -p 'alpine' ssh -o StrictHostKeyChecking=no -p2222 root@localhost "echo 'connected'")
	if [ "$check" = 'connected' ]; then
		"$sshpass" -p 'alpine' ssh -o StrictHostKeyChecking=no -p2222 root@localhost
	elif [ -z "$check" ] && [ $platform = 'Linux' ]; then
		echo '[-] Force closing usbmuxd ...'
		sudo systemctl stop usbmuxd
		sudo usbmuxd -p -f
	fi
		exit
fi

		##############################
		#      Optional switchs      #
		##############################
		
	if [ "$patch_iboot_with" = '2' ]; then
		patch_iboot_with='iBoot64Patcher' # Windows users
	else
		patch_iboot_with='kairos' # use kairs by default
	fi
	
	if [ "$pack_ramdisk_with" = '2' ]; then
		pack_ramdisk_with='img4tool'
	else
		pack_ramdisk_with='img4' # use img4 by default
	fi


		input_folder='1_prepare_ramdisk'
		temp_folder='2_ssh_ramdisk/temp_files'
		if [ ! -d "$input_folder" ]; then mkdir -p "$input_folder"; fi
		if [ ! -d "$temp_folder" ]; then mkdir -p "$temp_folder"; fi
	
	if [ ! -s 'misc/sshtars/ssh.tar' ]; then
		# tar format are used by hfsplus
		echo '[-] Extracting sshtars ...'
		tar -xvf './misc/sshtars/ssh.tar.xz'
		mv -f './ssh.tar' './misc/sshtars/ssh.tar'
	fi
	if [ -s 'misc/sshtars/ssh.tar' ] && [ ! -s 'misc/sshtars/ssh.tar.gz' ] && [ "$platform" = 'Darwin' ]; then
		echo '[-] Compressing sshtars into gz ...'
		echo '[!] Special step for Darwin users (hdutil)'
		gzip -9 -k './misc/sshtars/ssh.tar'
	fi
		
		# Get firmware keys and download ramdisk
		# Note: all variables are coming from here !
		#set -- "$@" '-r -k -o1_prepare_ramdisk' # makes sure to always download the ramdisk and decryption keys
		export OPTIND='1' # zsh may not work ?
	if [ "$pwndfu_decrypt" = 'yes' ]; then
		source './ifirmware_parser.sh' "${args[@]}" -r -o "$input_folder"
	elif [ "$pwndfu_decrypt" = '' ]; then
		source './ifirmware_parser.sh' "${args[@]}" -k -r -o "$input_folder"
		if [ "$ibec_key" = "" ] && [ "$ibss_key" = '' ]; then echo '[e] Decryptions keys are not set !'; exit; fi
	fi

		# b£tter organize
		input_folder="$input_folder/${product_name}_${product_model}_${build_version}"
		mkdir -p "$input_folder"

		check_ios="$major_ios""$minor_ios"
		output_folder='2_ssh_ramdisk/'"$product_name"_"$product_model"_"$build_version"
		if [ ! -d "$output_folder" ]; then mkdir "$output_folder"; fi
		
		ibec_file="$input_folder"'/'"$ibec_file"
		ibss_file="$input_folder"'/'"$ibss_file"
		iboot_file="$input_folder"'/'"$iboot_file"
		kernel_file="$input_folder"'/'"$kernel_file"
		ramdisk_file="$input_folder"'/'"$ramdisk_file"
		trustcache_file="$input_folder"'/'"$trustcache_file"
		devicetree_file="$input_folder"'/'"$devicetree_file"
		
		# Set boot arguments
		if [ "$cpid" = '0x8960' ] || [ "$cpid" = '0x7000' ] || [ "$cpid" = '0x7001' ]; then boot_args='rd=md0 debug=0x2014e -v wdt=-1 nand-enable-reformat=1 -restore -n'; else boot_args='rd=md0 debug=0x2014e -v wdt=-1 -n'; fi



		##############################
		#      Second Stage Make     #
		##############################

	########## iBEC/iBSS/iBoot ##########

		# Convert shsh ticket into binary
		"$img4tool" -e -s 'misc/shsh/'"$cpid"'.shsh' -m "$temp_folder"'/shsh.bin'
		shsh_file="$temp_folder"'/shsh.bin'

	if [ "$pwndfu_decrypt" = 'yes' ]; then
		# Decyrpt ibec/ibss/iboot with gaster
		echo '[!] Decrypting with gaster...'
		echo '[!] Please make sure to put your device into DFU mode'
		if [ "$platform" = 'Linux' ] || [ "$platform" = 'Darwin' ]; then echo "[Hint] If you stuck here then close the script and run it again with sudo"; fi
		if [ "$platform" = 'Windows' ]; then echo "[Hint] Windows: If you are using MSYS2 then maybe you won't be able to see any output."; fi
		"$gaster" pwn
		printf -- "- Copying iboot files to: './'\n"
		cp "$ibec_file" './iBEC.raw'
		cp "$ibss_file" './iBSS.raw'
		cp "$iboot_file" './iBoot.raw'
		"$gaster" decrypt './iBEC.raw' './iBEC.dec'
		"$gaster" decrypt './iBSS.raw' './iBSS.dec'
		"$gaster" decrypt './iBoot.raw' './iBoot.dec'
		mv './'*.dec "$temp_folder"
	fi

	if [ "$pwndfu_decrypt" != 'yes' ]; then
		# Decrypt ibec/ibss/iboot with img4
		"$img4" -i "$ibec_file" -o "$temp_folder"'/iBEC.dec' -k "$ibec_key"
		"$img4" -i "$ibss_file" -o "$temp_folder"'/iBSS.dec' -k "$ibss_key"
		"$img4" -i "$iboot_file" -o "$temp_folder"'/iBoot.dec' -k "$iboot_key"
	fi
		
	if [ "$check_ios" -ge '150' ] && [ "$patch_iboot_with" = 'kairos' ]; then
		# I think kairos works better for iOS 15.x and above
		# However user can select which one to use !
		
		# Patch ibec/ibss/iboot using kairos
		echo '[-] Patching iBoot files using kairos ...'
		"$kairos" "$temp_folder"'/iBSS.dec' "$temp_folder"'/iBSS.patched'
		"$kairos" "$temp_folder"'/iBEC.dec' "$temp_folder"'/iBEC.patched' -b "$boot_args"
		"$kairos" "$temp_folder"'/iBoot.dec' "$temp_folder"'/iBoot.patched'
	else
		# Patch ibec/ibss/iboot using iboot64patcher
		echo '[-] Patching iBoot files using iBoot64Patcher ...'
		"$iBoot64Patcher" "$temp_folder"'/iBSS.dec' "$temp_folder"'/iBSS.patched'
		"$iBoot64Patcher" "$temp_folder"'/iBEC.dec' "$temp_folder"'/iBEC.patched' -b "$boot_args"
		"$iBoot64Patcher" "$temp_folder"'/iBoot.dec' "$temp_folder"'/iBoot.patched'
	fi


		# Pack ibec/ibss/iboot into img4
		"$img4" -i "$temp_folder"'/iBSS.patched' -o "$output_folder"'/iBSS.img4' -M "$shsh_file" -A -T ibss
		"$img4" -i "$temp_folder"'/iBEC.patched' -o "$output_folder"'/iBEC.img4' -M "$shsh_file" -A -T ibec
		"$img4" -i "$temp_folder"'/iBoot.patched' -o "$output_folder"'/iBoot.img4' -M "$shsh_file" -A -T ibot


	########## KernelCache ##########
		
		# Convert kernelcache into raw image
		"$img4" -i "$kernel_file" -o "$temp_folder"'/kcache.raw'

		# Patch kernelcache
		"$KPlooshFinder" "$temp_folder"'/kcache.raw' "$temp_folder"'/kcache.patched'

		echo '[-] Searching for kernel differents...'
		echo '[!] this could take a while please wait...'
		"$kerneldiff" "$temp_folder"'/kcache.raw' "$temp_folder"'/kcache.patched' "$temp_folder"'/kc.bpatch'

		# Pack kernelcache into img4
		"$img4" -i "$kernel_file" -o "$output_folder"'/kernelcache.img4' -M "$shsh_file" -T rkrn -P "$temp_folder"'/kc.bpatch' `if [ "$platform" = 'Linux' ]; then echo '-J'; fi`
		echo '[-] Patching kernel completed !'


	########## DeviceTree/TrustCache ##########

		# Pack devicetree into img4
		"$img4" -i "$devicetree_file" -o "$output_folder"'/devicetree.img4' -M "$shsh_file" -T rdtr


		# iOS 11 and below doesn't need trustcache
	if [ -s "$trustcache_file" ]; then

		# Pack trustcache into img4
		echo '[!] Found trustcache file :' "$trustcache_file"
		"$img4" -i "$trustcache_file" -o "$output_folder"'/trustcache.img4' -M "$shsh_file" -T rtsc
	fi


	########## RAMDISK ##########
		
		# Convert ramdisk into raw image
		"$img4" -i "$ramdisk_file" -o "$temp_folder"'/ramdisk.dmg'

		# iOS 16.1.x and newer uses apfs
if [ "$platform" != 'Darwin' ] && [ "$check_ios" -lt '161' ]; then
		
		# Resign ramdisk
		"$hfsplus" "$temp_folder"'/ramdisk.dmg' grow 210000000
		# Copy ssh files into ramdisk
		"$hfsplus" "$temp_folder"'/ramdisk.dmg' untar 'misc/sshtars/ssh.tar'
	
	elif [ "$platform" = 'Darwin' ] && [ "$check_ios" -ge '161' ]; then
		hdiutil attach -mountpoint '/tmp/SSHRD' "$temp_folder"'/ramdisk.dmg'
		hdiutil create -size 210m -imagekey diskimage-class=CRawDiskImage -format UDZO -fs HFS+ -layout NONE -srcfolder '/tmp/SSHRD' -copyuid root "$temp_folder"'/reassigned_ramdisk.dmg'
        hdiutil detach -force '/tmp/SSHRD'
        hdiutil attach -mountpoint '/tmp/SSHRD' "$temp_folder"'/reassigned_ramdisk.dmg'
		./tools/Darwin/gtar -x --no-overwrite-dir -f 'misc/sshtars/ssh.tar.gz' -C '/tmp/SSHRD/'
		hdiutil detach -force '/tmp/SSHRD'
		hdiutil resize -sectors min "$temp_folder"'/reassigned_ramdisk.dmg'
	elif [ "$platform" = 'Darwin' ] && [ "$check_ios" -lt '161' ]; then
		echo '[!] Warnning creating RAMDISK may fail on iOS 11.3 or lower.'
		hdiutil resize -size 210MB "$temp_folder"'/ramdisk.dmg'
		hdiutil attach -mountpoint '/tmp/SSHRD' "$temp_folder"'/ramdisk.dmg'
		./tools/Darwin/gtar -x --no-overwrite-dir -f 'misc/sshtars/ssh.tar.gz' -C '/tmp/SSHRD/'
		hdiutil detach -force '/tmp/SSHRD'
		hdiutil resize -sectors min "$temp_folder"'/ramdisk.dmg'
	elif [ "$platform" != 'Darwin' ] && [ "$check_ios" -ge '161' ]; then
		echo "[!] Warnning we are missing a utility for handling APFS system!"
		echo "[!] Please select lower than iOS 16.1 and try again."
fi

		echo '[-] Packing ramdisk into img4 ...'
	if [ "$platform" = 'Darwin' ] && [ "$check_ios" -ge '161' ]; then
	
		# Pack ramdisk for darwin iOS 16.1 and above
		echo '[-] Packing using img4 utility ...'
		"$img4" -i "$temp_folder"'/reassigned_ramdisk.dmg' -o "$output_folder"'/ramdisk.img4' -M "$shsh_file" -A -T rdsk
		
	elif [ "$platform" = 'Windows' ] && [ "$pack_ramdisk_with" = 'img4tool' ]; then
		echo '[!] Warnning you have selected packing ramdisk.dmg with img4tool'
		echo 'img4tool are faster than img4 in packing process'
		echo 'however packing with img4tool may result in failing to boot the RAMDISK'
		echo 'please note that this option is only available for Windows users.'
		echo ''
		echo '[-] Packing using img4tool ...'
		"$img4tool" -i "$temp_folder"'/ramdisk.dmg' -c "$output_folder"'/ramdisk.img4' -s "$shsh_file" -t rdsk

	else
 		# Pack ramdisk for linux windows and darwin
		"$img4" -i "$temp_folder"'/ramdisk.dmg' -o "$output_folder"'/ramdisk.img4' -M "$shsh_file" -A -T rdsk
		
	fi


	########## Boot logo ##########

		# Pack logo into img4
		"$img4" -i 'misc/bootlogo.im4p' -o "$output_folder"'/logo.img4' -M "$shsh_file" -A -T rlgo

  		# Clean temp folder
		echo '[-] Cleaning temp directory ...'
		rm -rf "$temp_folder"

		echo '[!] All Tasks Completed !'
		echo '[-] To boot this SSHRD please use: ./boot_sshrd.sh'