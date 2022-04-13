#!/bin/bash
#Copyrigth (c) 2021 by profzei
#Licensed under the terms of the GPL v3

sudo apt update && sudo apt upgrade

if ! command -v unzip &> /dev/null
then
	echo "Installing unzip..."
	sudo apt install unzip
fi

if ! command -v sbsign &> /dev/null
then
	echo "Installing sbsigntool..."
	sudo apt-get install sbsigntool
fi

if ! command -v cert-to-efi-sig-list &> /dev/null
then
	echo "Installing efitools..."
	sudo apt-get install efitools
fi

VERSION=$1

echo "=============================="
echo "Creating efikeys folder"
mkdir efikeys
cd efikeys
openssl req -new -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes -subj "/CN=KEYS PK/" -keyout PK.key -out PK.pem
openssl req -new -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes -subj "/CN=KEYS KEK/" -keyout KEK.key -out KEK.pem
openssl req -new -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes -subj "/CN=KEYS ISK/" -keyout ISK.key -out ISK.pem
chmod 0600 *.key

echo "============================="
echo "Downloading Microsoft certificates..."
wget --user-agent="Mozilla" https://www.microsoft.com/pkiops/certs/MicWinProPCA2011_2011-10-19.crt
wget --user-agent="Mozilla" https://www.microsoft.com/pkiops/certs/MicCorUEFCA2011_2011-06-27.crt

echo "============================="
echo "Signing certificates..."
openssl x509 -in MicWinProPCA2011_2011-10-19.crt -inform DER -out MicWinProPCA2011_2011-10-19.pem -outform PEM
openssl x509 -in MicCorUEFCA2011_2011-06-27.crt -inform DER -out MicCorUEFCA2011_2011-06-27.pem -outform PEM

echo "============================="
echo "Converting PEM to ESL..."
cert-to-efi-sig-list -g $(uuidgen) PK.pem PK.esl
cert-to-efi-sig-list -g $(uuidgen) KEK.pem KEK.esl
cert-to-efi-sig-list -g $(uuidgen) ISK.pem ISK.esl
cert-to-efi-sig-list -g $(uuidgen) MicWinProPCA2011_2011-10-19.pem MicWinProPCA2011_2011-10-19.esl
cert-to-efi-sig-list -g $(uuidgen) MicCorUEFCA2011_2011-06-27.pem MicCorUEFCA2011_2011-06-27.esl


echo "============================="
echo "Creating database of allowed signs..."
cat ISK.esl MicWinProPCA2011_2011-10-19.esl MicCorUEFCA2011_2011-06-27.esl > db.esl


echo "============================="
echo "Signing ESL files..."
sign-efi-sig-list -k PK.key -c PK.pem PK PK.esl PK.auth
sign-efi-sig-list -k PK.key -c PK.pem KEK KEK.esl KEK.auth
sign-efi-sig-list -k KEK.key -c KEK.pem db db.esl db.auth

cd ..
mkdir oc
cp efikeys/ISK.key oc
cp efikeys/ISK.pem oc
cp efikeys/PK.auth oc
cp efikeys/KEK.auth oc
cp efikeys/db.auth oc
cd oc

echo "============================="
LINK="https://github.com/acidanthera/OpenCorePkg/releases/download/${VERSION}/OpenCore-${VERSION}-RELEASE.zip"
echo "Downlading Opencore ${VERSION}"
wget -nv $LINK
echo "============================="
echo "Creating required directories"
mkdir Signed
mkdir Signed/Drivers
mkdir Signed/Tools
mkdir Signed/Download
mkdir Signed/BOOT
echo "============================="
echo "Downloading HfsPlus.efi"
wget -nv https://github.com/acidanthera/OcBinaryData/raw/master/Drivers/HfsPlus.efi -O ./Signed/Download/HfsPlus.efi
echo "============================="
echo "Do you use OpenLinuxBoot? (Y/N)"
read LUKA
LUKA1="Y"
LUKA2="y"
if [ "$LUKA" = "$LUKA1" ] || [ "$LUKA" = "$LUKA2" ]; then
	wget -nv https://github.com/acidanthera/OcBinaryData/raw/master/Drivers/ext4_x64.efi -O ./Signed/Download/ext4_x64.efi	
fi

echo "============================="
echo "Unzipping OpenCore ${VERSION}"
unzip "OpenCore-${VERSION}-RELEASE.zip" "X64/*" -d "./Signed/Download"
rm "OpenCore-${VERSION}-RELEASE.zip"
echo "============================"
echo "Signing drivers, tools, BOOTx64.efi and OpenCore.efi"
echo ""
sbsign --key ISK.key --cert ISK.pem --output ./Signed/EFI/BOOT/BOOTx64.efi ./Signed/Download/X64/EFI/BOOT/BOOTx64.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/EFI/OC/OpenCore.efi ./Signed/Download/X64/EFI/OC/OpenCore.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/EFI/OC/Drivers/OpenRuntime.efi ./Signed/Download/X64/EFI/OC/Drivers/OpenRuntime.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/EFI/OC/Drivers/OpenCanopy.efi ./Signed/Download/X64/EFI/OC/Drivers/OpenCanopy.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/EFI/OC/Drivers/CrScreenshotDxe.efi ./Signed/Download/X64/EFI/OC/Drivers/CrScreenshotDxe.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/EFI/OC/Tools/OpenShell.efi ./Signed/Download/X64/EFI/OC/Tools/OpenShell.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/EFI/OC/Drivers/HfsPlus.efi ./Signed/Download/HfsPlus.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/EFI/OC/Drivers/AudioDxe.efi ./Signed/Download/X64/EFI/OC/Drivers/AudioDxe.efi


if [ "$LUKA" = "$LUKA1" ] || [ "$LUKA" = "$LUKA2" ]; then
	sbsign --key ISK.key --cert ISK.pem --output ./Signed/Drivers/OpenLinuxBoot.efi ./Signed/Download/X64/EFI/OC/Drivers/OpenLinuxBoot.efi
	sbsign --key ISK.key --cert ISK.pem --output ./Signed/Drivers/ext4_x64.efi ./Signed/Download/ext4_x64.efi
	echo "Linux drivers signed"
else
	rm ./Signed/Download/X64/EFI/OC/Drivers/OpenLinuxBoot.efi
fi

echo "============================"
echo "Cleaning..."
rm -rf ./Signed/Download
rm ISK.key
rm ISK.pem
cd ..
rm -rf ./efikeys
echo "Cleaned"

echo "============================"
echo "Copying files to Windows"
a=$(powershell.exe '$env:UserName')
a=${a%?}
cp -R oc "/mnt/c/Users/$a/Downloads"
echo "Everything is done, enjoy!"
rm -rf oc

echo "============================"
echo "====CREATED BY LUKAKEITON==="
echo "============================"
