#!/usr/bin/bash

		
	if [ "$1" = '' ] || [ "$1" = '-h' ] || [ "$1" = '-help' ] || [ "$1" = '--help' ]; then
		echo '[-] Usage: sshrd_lite.sh -p product_name -s ios_version'
		echo '[-] Optional:'
		echo '           -g/--gaster (decrypt with gaster)'
		echo '           --boot/--patch-iboot-with number (1 = iBoot64Patcher / 2 = kairos)'
		echo '           --img4/--pack-img4-with number (1 = img4 / 2 = img4tool)'
		echo
		echo '[-] For more info see "ifirmware_parser.sh -h"'
	exit 1
	fi

		##############################
		#       Initialization       #
		##############################

	if [ -s 'ifirmware_parser/README.md' ]; then
		echo '[-] Setting-up ifirmware parser (for first run) ...'
		mv -f './ifirmware_parser/ifirmware_parser.sh' './'
		mv -f './ifirmware_parser/ca-bundle.crt' './'
		cp -Rf './ifirmware_parser/misc' './'
		echo "[!] Removing 'ifirmware_parser' folder ..."
		rm -Rf './ifirmware_parser'
	elif [ ! -s 'misc/platform_check.sh' ] || [ ! -s 'ifirmware_parser.sh' ]; then
		echo '[!] Required module are missing ...'
		echo '[!] Downloading ifirmware parser module ...'
		echo '[!] Submodule link: https://github.com/mast3rz3ro/ifirmware_parser'
		git submodule update --init
		exit 1
	fi
		
		source './misc/platform_check.sh' # Check platform and set tools
		
		chmod -R +x 'tools/'
		chmod +x './ifirmware_parser.sh' './misc/platform_check.sh' './boot_sshrd.sh'

		while true; do
		case "$1" in
        -p|--product) product_name="$2"; shift;;
        -s|--ios) switch="-s"; version="$2"; shift;;
        -b|--build) switch="-b"; version="$2"; shift;;
        --boot|--patch-iboot-with) patch_iboot_with="$2"; shift;;
        --img4|--pack-img4-with) pack_img4_with="$2"; shift;;
        *) break
		esac
		shift
		done
	
	
		##############################
		#      Optional switchs      #
		##############################
		
		# Clean the variable
		bp_switch=''
		
	if [ "$patch_iboot_with" = '1' ]; then
		patch_iboot_with='iBoot64Patcher'
	elif [ "$patch_iboot_with" = '2' ]; then
		patch_iboot_with='kairos'
	else
		patch_iboot_with='iBoot64Patcher'
		# haiyuidesu fork of iBoot64Patcher uses -p switch (this is are required for windows)
		if [ "$platform" = 'Windows' ]; then bp_switch='-p'; fi
	fi
	
	if [ "$pack_img4_with" = '1' ]; then
		pack_img4_with='img4'
	elif [ "$pack_img4_with" = '2' ]; then
		pack_img4_with='img4tool'
	else
		pack_img4_with='img4'
	fi
		
		# Enable decrypting with pwned dfu mode
	if [[ $1 = '-g' || $2 = '-g' || $3 = '-g' || $4 = '-g' || $5 = '-g' || $6 = '-g' ]]; then pwndfu_decrypt="YES"; fi
	if [[ $1 = '-gaster' || $2 = '-gaster' || $3 = '-gaster' || $4 = '-gaster' || $5 = '-gaster' || $6 = '-gaster' ]]; then pwndfu_decrypt="YES"; fi
		
		
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
		source './ifirmware_parser.sh' -p "$product_name" "$switch" "$version" -o "$input_folder" -r
		if [ "$ibec_key" = "" ] && [ "$ibss_key" = '' ]; then echo '[!] Decryptions keys are not set !'; exit; fi


		check_ios="$major_ios""$minor_ios"
		output_folder='2_ssh_ramdisk/'"$product_json"_"$model_json"_"$build_json"
		if [ ! -d "$output_folder" ]; then mkdir "$output_folder"; fi
		
		ibec_file="$input_folder"'/'"$ibec_file"
		ibss_file="$input_folder"'/'"$ibss_file"
		iboot_file="$input_folder"'/'"$iboot_file"
		kernel_file="$input_folder"'/'"$kernel_file"
		ramdisk_file="$input_folder"'/'"$ramdisk_file"
		trustcache_file="$input_folder"'/'"$trustcache_file"
		devicetree_file="$input_folder"'/'"$devicetree_file"
		
		# Set boot arguments
		if [ "$cpid_json" = '0x8960' ] || [ "$cpid_json" = '0x7000' ] || [ "$cpid_json" = '0x7001' ]; then boot_args='rd=md0 debug=0x2014e -v wdt=-1 nand-enable-reformat=1 -restore -n'; else boot_args='rd=md0 debug=0x2014e -v wdt=-1 -n'; fi



		##############################
		#      Second Stage Make     #
		##############################

	########## iBEC/iBSS/iBoot ##########

		# Convert shsh ticket into binary
		"$img4tool" -e -s 'misc/shsh/'"$cpid_json"'.shsh' -m "$temp_folder"'/shsh.bin'
		shsh_file="$temp_folder"'/shsh.bin'

	if [ "$pwndfu_decrypt" = 'YES' ]; then
		# Decyrpt ibec/ibss/iboot with gaster
		echo '[!] Decrypting with gaster...'
		echo '[!] Please make sure to put your device into DFU mode'
		if [ "$platform" = 'Linux' ]; then echo "[Hint] Linux: If you stuck here then close the script and run again as root."; fi
		if [ "$platform" = 'Windows' ]; then echo "[Hint] Windows: If you are using MSYS2 then maybe you won't be able to see any output."; fi
		"$gaster" pwn
		"$gaster" decrypt "$ibec_file" "$temp_folder"'/iBEC.dec'
		"$gaster" decrypt "$ibss_file" "$temp_folder"'/iBSS.dec'
		"$gaster" decrypt "$iboot_file" "$temp_folder"'/iBoot.dec'
	fi

	if [ "$pwndfu_decrypt" != 'YES' ]; then
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
		"$iBoot64Patcher" $bp_switch "$temp_folder"'/iBSS.dec' "$temp_folder"'/iBSS.patched'
		"$iBoot64Patcher" $bp_switch "$temp_folder"'/iBEC.dec' "$temp_folder"'/iBEC.patched' -b "$boot_args"
		"$iBoot64Patcher" $bp_switch "$temp_folder"'/iBoot.dec' "$temp_folder"'/iBoot.patched'
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
		gtar -x --no-overwrite-dir -f 'misc/sshtars/ssh.tar.gz' -C '/tmp/SSHRD/'
		hdiutil detach -force '/tmp/SSHRD'
		hdiutil resize -sectors min "$temp_folder"'/reassigned_ramdisk.dmg'
	elif [ "$platform" = 'Darwin' ] && [ "$check_ios" -lt '161' ]; then
		echo '[Warnning] Creating RAMDISK may fail on iOS 11.3 or lower.'
		hdiutil resize -size 210MB "$temp_folder"'/ramdisk.dmg'
		hdiutil attach -mountpoint '/tmp/SSHRD' "$temp_folder"'/ramdisk.dmg'
		gtar -x --no-overwrite-dir -f 'misc/sshtars/ssh.tar.gz' -C '/tmp/SSHRD/'
		hdiutil detach -force '/tmp/SSHRD'
		hdiutil resize -sectors min "$temp_folder"'/ramdisk.dmg'
	elif [ "$platform" != 'Darwin' ] && [ "$check_ios" -ge '161' ]; then
		echo "[Warnning] We are missing a utility for handling APFS system!"
		echo "[!] Please select lower than iOS 16.1 and try again."
fi

		echo '[-] Packing ramdisk into img4 ...'
	if [ "$platform" = 'Darwin' ] && [ "$check_ios" -ge '161' ]; then
	
		# Pack ramdisk for darwin iOS 16.1 and above
		echo '[-] Packing using img4 utility ...'
		"$img4" -i "$temp_folder"'/reassigned_ramdisk.dmg' -o "$output_folder"'/ramdisk.img4' -M "$shsh_file" -A -T rdsk
		
	elif [ "$platform" = 'Windows' ] && [ "$pack_img4_with" = 'img4tool' ]; then
		echo '[WARNNING] You have selected packing ramdisk.dmg with img4tool'
		echo " the img4 fork has in Windows can take a lot of time when packing ramdisk.dmg"
		echo ' however using img4tool can also result in failing to boot'
		echo ' please note that this option is only available for Windows users.'
		echo
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
		echo '[-] To boot this SSHRD please use below command:'
		echo './boot_sshrd.sh -p' "$product_json" '-b' "$build_json"


