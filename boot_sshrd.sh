#!/usr/bin/bash


	if [ "$1" = '' ] || [ "$1" = '-h' ] || [ "$1" = '-help' ] || [ "$1" = '--help' ]; then
		echo '[-] Usage: boot_sshrd.sh -p product_name -s ios_version'
		echo '[-] For more info see "ifirmware_parser.sh -h"'
	exit 1
	fi
		source './misc/platform_check.sh' # Check platform and set tools
		source './ifirmware_parser.sh'
		bootchain='2_ssh_ramdisk/'"$product_json"_"$model_json"_"$build_json"


	if [ ! -s "$bootchain"'/iBEC.img4' ] && [ ! -s "$bootchain"'/iBSS.img4' ]; then
		echo '[Error] Error bootchain:' "'$bootchain'" 'does not exist'
		echo '[Hint] Please make it using:' "'./sshrd_lite.sh -p $product_json -b $build_json'"
		exit 1
	fi


		echo '[-] Reading connected device info ...'
		echo '[!] Please make sure to put your device into DFU mode'
		cpid=$($irecovery -q | grep CPID | sed 's/CPID: //')
		pwn=$($irecovery -q | grep PWND | sed 's/PWND: //')
		
		if [ "$cpid" = '' ]; then exit 1; fi
		
if [ "$pwn" = '' ]; then

		echo '[!] Starting to pwn the deviec...'
		"$gaster" pwn
		# "$gaster" reset # Windows users has issue with gaster drivers
fi
		echo '[!] Starting SSHRD booting...'

		echo '[-] Sending iBSS ...'
		ibss_check=$("$irecovery" -v -f "$bootchain"'/iBSS.img4' | grep -o '100')
if [ "$ibss_check" != '100' ]; then
		# If iBSS already sent then do not send it again !
		"$irecovery" -v -f "$bootchain"'/iBSS.img4'
fi
		sleep 3
		
		echo '[-] Sending iBEC ...'
		"$irecovery" -v -f "$bootchain"'/iBEC.img4'
		sleep 10

if [ "$cpid" = '0x8010' ] || [ "$cpid" = '0x8015' ] || [ "$cpid" = '0x8011' ] || [ "$cpid" = '0x8012' ]; then
		"$irecovery" -c go
		sleep 3
fi
		"$irecovery" -v -f "$bootchain"'/logo.img4'
		"$irecovery" -v -c 'setpicture 0x1'
		
		echo '[-] Sending ramdisk ...'
		"$irecovery" -v -f "$bootchain"'/ramdisk.img4'
		"$irecovery" -v -c ramdisk
		
		echo '[-] Sending devicetree ...'
		"$irecovery" -v -f "$bootchain"'/devicetree.img4'
		"$irecovery" -v -c devicetree

if [ ! -s "$bootchain"'/trustcache.img4' ] && [ "$cpid" = '0x8012' ]; then
		: # do nothing
else
		echo '[-] Sending trustcache ...'
		"$irecovery" -v -f "$bootchain"'/trustcache.img4'
		"$irecovery" -v -c firmware
fi

		echo '[-] Sending kernelcache ...'
		"$irecovery" -v -f "$bootchain"'/kernelcache.img4'
		"$irecovery" -v -c bootx
		
		echo '[!] SSHRD Booting has completed!'


  
