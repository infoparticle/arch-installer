#!/bin/bash
# encoding: utf-8
# https://goo.gl/gfPFgb
set -x
HOSTN=Singularity
KEYBOARD_LAYOUT=us
LANGUAGE=en_US
LOCALE=Asia/Calcutta
ROOT_PASSWD=123456

#### Installation
echo "Setting up pacman"
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bkp
sed "s/^Ser/#Ser/" /etc/pacman.d/mirrorlist > /tmp/mirrors
sed '/India/{n;s/^#//}' /tmp/mirrors > /etc/pacman.d/mirrorlist

if [ "$(uname -m)" = "x86_64" ]
then
	cp /etc/pacman.conf /etc/pacman.conf.bkp
	# Adds multilib repository
	sed '/^#\[multilib\]/{s/^#//;n;s/^#//;n;s/^#//}' /etc/pacman.conf > /tmp/pacman
	mv /tmp/pacman /etc/pacman.conf

fi

echo "Refreshing pacman keys, this will take some time"

pacman-key --init; pacman-key --populate archlinux; pacman-key --refresh-keys

echo "Running pactrap base base-devel"
pacstrap /mnt base base-devel
echo "Running pactrap grub-bios $EXTRA_PKGS"
pacstrap /mnt grub-bios `echo $EXTRA_PKGS`
echo "Running genfstab"
genfstab -p /mnt >> /mnt/etc/fstab
echo "Installing wifi"
pacstrap /mnt dialog wpa_supplicant


#### Enters in the new system (chroot)
arch-chroot /mnt << EOF
# Sets hostname
echo $HOSTN > /etc/hostname
cp /etc/hosts /etc/hosts.bkp
sed 's/localhost$/localhost '$HOSTN'/' /etc/hosts > /tmp/hosts
mv /tmp/hosts /etc/hosts

# Configures the keyboard layout
echo 'KEYMAP='$KEYBOARD_LAYOUT > /etc/vconsole.conf
echo 'FONT=lat0-16' >> /etc/vconsole.conf
echo 'FONT_MAP=' >> /etc/vconsole.conf

# Setup locale.gen
cp /etc/locale.gen /etc/locale.gen.bkp
sed 's/^#'$LANGUAGE'/'$LANGUAGE/ /etc/locale.gen > /tmp/locale
mv /tmp/locale /etc/locale.gen
locale-gen

# Setup locale.conf
export LANG=$LANGUAGE'.utf-8'
echo 'LANG='$LANGUAGE'.utf-8' > /etc/locale.conf
echo 'LC_COLLATE=C' >> /etc/locale.conf
echo 'LC_TIME='$LANGUAGE'.utf-8' >> /etc/locale.conf

# Setup clock (date and time)
unlink /etc/localtime
ln -s /usr/share/zoneinfo/$LOCALE /etc/localtime
echo $LOCALE > /etc/timezone
hwclock --systohc --utc

# Setup the network (DHCP via eth0)
#cp /etc/rc.conf /etc/rc.conf.bkp
#sed 's/^# interface=/interface=eth0/' /etc/rc.conf > /tmp/rc.conf
#mv /tmp/rc.conf /etc/rc.conf

# Setup initial ramdisk environment
mkinitcpio -p linux

# Installs and generates GRUB's settings
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# Changes the root password
echo -e $ROOT_PASSWD"\n"$ROOT_PASSWD | passwd
EOF

echo "Next Action: Umounting partitions and rebooting"
echo "umount /mnt/{boot,home,}"
echo "reboot"
