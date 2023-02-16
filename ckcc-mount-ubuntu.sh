#!/bin/bash
function createRamDisk(){
	sudo modprobe brd rd_nr=1 rd_size=$2 max_part=1
	sudo mkfs -T ext2 /dev/ram0
	mkdir $1
	sudo mount /dev/ram0 $1
	sudo chmod a+w $1
}
function ejectRamDisk(){
	sudo umount $1
	sudo rm -rfv $1
	sudo rmmod brd
}
function ccpass(){
	local password=$(echo $1|openssl sha512 -hmac 'nonbase64key'|sed 's/^.* //')
	local msg=$(ckcc msg -j $password 2>/dev/null)
	if [ "" == "$msg" ]; then 
		echo "Empty signature!"
		exit
	fi
	echo $msg|openssl sha512 -hmac "nonbase64key" --binary
}
function ccaskpass(){
	local password=""
	read -s -p "Sign Password: " password
	local keypass=$(ccpass $password)
	password=""
	echo -n $keypass
}
function tmpkey(){
	local tmpvolname="$(openssl rand -hex 16 2>/dev/null)"
	local tmpfilename="$(openssl rand -hex 16 2>/dev/null)"
	local tmppath="/tmp/$tmpvolname/$tmpfilename"
	local cckey="$(ccaskpass)"
	local mount="$(createRamDisk /tmp/$tmpvolname 1024 2>/dev/null)"
	echo -n $cckey>$tmppath
	echo -n $tmppath
}
function destroytmpkey(){
	local tmpkeypath=$1
	shred --force --iterations 16 --exact --zero --remove=wipesync $tmpkeypath 2>/dev/null
	local tmpvolpath="$(dirname "${tmpkeypath}")"
	local tmpeject="$(ejectRamDisk $tmpvolpath 2>/dev/null)"
}
function veratmpmount(){
	local tmpkeypath="$(tmpkey)"
	echo
	echo "tmpkey: $tmpkeypath"
	veracrypt $1 -k $tmpkeypath
	destroytmpkey $tmpkeypath
}
function veratmpcreate(){
	local tmpkeypath=$(tmpkey)
	echo
	echo "tmpkey: $tmpkeypath"
	veracrypt -c -k $tmpkeypath $1
	destroytmpkey $tmpkeypath
}
