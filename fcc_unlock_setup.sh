#! /bin/bash
# vim: ts=4:noet

TARGET_DIR="/opt/fcc_lenovo"
SYSTEMD_DIR="/etc/systemd/system"

echo "Copying files and libraries..."
sudo mkdir -p "$TARGET_DIR"

### Identify current OS
OS_UBUNTU="Ubuntu"
OS_FEDORA="Fedora"

source /etc/os-release
echo $NAME

CP_OPTS="-rvf"

LIB_FILES=("libconfigserviceR+.so" "libconfigservice350.so" "libmbimtools.so")
LIB64_FILES=("libmodemauth.so")
BIN_FILES=("DPR_Fcc_unlock_service" "configservice_lenovo")

case $NAME in
	*"$OS_UBUNTU"*)
		LIB_PATH="/usr/lib"
		LIB64_PATH="/usr/lib"
		LIB_MM_PATH="/usr/lib/x86_64-linux-gnu/ModemManager"
		;;
	*"$OS_FEDORA"*)
		LIB_PATH="/usr/lib"
		LIB64_PATH="/usr/lib64"
		LIB_MM_PATH="/usr/lib64/ModemManager"
		CIL_FILES=("mm_FccUnlock.cil" "mm_dmidecode.cil" "mm_sh.cil")

		ln -s /usr/sbin/lspci /usr/bin/lspci
		;;
	*)
		echo "No need to copy files"
		exit 0
		;;
esac

### Copy fcc unlock script for MM
sudo tar -zxf fcc-unlock.d.tar.gz -C "$LIB_MM_PATH"
sudo chmod ugo+x "$LIB_MM_PATH/fcc-unlock.d/*"

### Copy SAR config files
sudo tar -zxf sar_config_files.tar.gz -C "$TARGET_DIR"

### Copy libraries
for file in "${LIB_FILES[@]}"
do
	sudo cp $CP_OPTS "$file" "$LIB_PATH"
done

for file in "${LIB64_FILES[@]}"
do
	sudo cp $CP_OPTS "$file" "$LIB64_PATH"
done

### Copy binary
for file in "${BIN_FILES[@]}"
do
	sudo cp $CP_OPTS "$file" "$TARGET_DIR"
done

### Copy files for selinux
# shellcheck disable=SC2128
if [ -n "$CIL_FILES" ]
then
	for file in "${CIL_FILES[@]}"
	do
		sudo cp $CP_OPTS "$file" "$TARGET_DIR"
	done
	sudo semodule -i "$TARGET_DIR/*.cil"
fi

### Copy and enable service
sudo cp $CP_OPTS lenovo-cfgservice.service "$SYSTEMD_DIR"
sudo systemctl daemon-reload
systemctl enable lenovo-cfgservice

### Grant permissions to all binaries and script
sudo chmod ugo+x "$TARGET_DIR/*"

## Please reboot machine (this will be needed only one for time)##

### Exit script
exit 0
