#!/bin/bash
# Required ckcc-protocol from https://github.com/Coldcard/ckcc-protocol
# pip install 'ckcc-protocol[cli]'

## Usage from bash-shell: source ./clcc-mount.sh
## Create with veracrypt:	veratmpcreate ~/Path/to/container
## Mount with veracrypt:	veratmpmount ~/Path/to/container
## Create with default macOS tools: createdisk ~/Path/to/container.dmg
## Mount with default macOS tools: mountdisk ~/Path/to/container.dmg

WIPE_CMD="/usr/local/Cellar/coreutils/9.1/bin/gshred --force --iterations 16 --exact --zero --remove=wipesync"
VERA_CMD="/opt/local/bin/veracrypt -t"
HASH_CMD_IN='openssl sha512 -hmac "nonbase64key"'
HASH_CMD_OUT='openssl sha512 -hmac "nonbase64key"'

function ramdisk(){
	diskutil erasevolume HFS+ "$1" `hdiutil attach -nomount "ram://$2"`
}
function ccpass(){
	local password=$(echo $1|$HASH_CMD_IN)
	local msg=$(ckcc msg -j $password 2>/dev/null)
	if [ "" == "$msg" ]; then 
		echo "Empty signature!"
		exit
	fi
	echo $msg|$HASH_CMD_OUT
}
function ccaskpass(){
	local password=""
	read -s -p "Sign Password: " password
	local keypass=$(ccpass $password)
	password=""
	echo -n $keypass
}
function tmpkey(){
	HASH_CMD_IN='openssl sha512 -hmac "nonbase64key"'
	HASH_CMD_OUT='openssl sha512 -hmac "nonbase64key" -binary'
	local tmpvolname="$(openssl rand -hex 16 2>/dev/null)"
	local tmpfilename="$(openssl rand -hex 16 2>/dev/null)"
	local tmppath="/Volumes/$tmpvolname/$tmpfilename"
	local cckey="$(ccaskpass)"
	local mount="$(ramdisk $tmpvolname 1024 2>/dev/null)"
	echo -n $cckey>$tmppath
	echo -n $tmppath
}
function destroytmpkey(){
	local tmpkeypath=$1
	$WIPE_CMD $tmpkeypath 2>/dev/null
	local tmpvolpath="$(dirname "${tmpkeypath}")"
	local tmpeject="$(hdiutil eject -force $tmpvolpath 2>/dev/null)"
}
function veratmpmount(){
	local tmpkeypath="$(tmpkey)"
	echo
	echo "tmpkey: $tmpkeypath"
	$VERA_CMD $1 -k $tmpkeypath
	destroytmpkey $tmpkeypath
}
function veratmpcreate(){
	local tmpkeypath=$(tmpkey)
	echo
	echo "tmpkey: $tmpkeypath"
	$VERA_CMD -c -k $tmpkeypath $1
	destroytmpkey $tmpkeypath
}
function createdisk(){
	HASH_CMD_IN='openssl sha512 -hmac "nonbase64key"'
	HASH_CMD_OUT='openssl sha512 -hmac "nonbase64key"'
	local cckey=$(ccaskpass)
	echo
	echo $cckey|hdiutil create $1 -size $2 -volname "$3" -fs JHFS+ -encryption AES-256 -stdinpass 2>/dev/null
}
function mountdisk(){
	HASH_CMD_IN='openssl sha512 -hmac "nonbase64key"'
	HASH_CMD_OUT='openssl sha512 -hmac "nonbase64key"'
	local cckey=$(ccaskpass)
	echo
	echo $cckey|hdiutil mount $1 -stdinpass 2>/dev/null
}
