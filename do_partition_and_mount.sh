#!/bin/bash
# encoding: utf-8
# credits & src: https://gist.github.com/magnunleno/3641682
# This script: https://goo.gl/jiRoPh

# Partition Scheme-1
# I have 500 GB HDD
# | HDD  | Name      |    Size | Comments                                                                                  |
# |------+-----------+---------+-------------------------------------------------------------------------------------------|
# | sda  |           |    1 MB | MBR                                                                                       |
# | sda1 | boot      |  500 MB |                                                                                           |
# | sda5 | swap      |    6 GB | enables hibernation                                                                       |
# | sda6 | root      |  100 GB | install bigger packages Gnome/Latex/Mathematica etc                                       |
# | sda7 | home      |    2 GB | hold only basic configs for user + cached items for user                                  |
# | sda8 | data      |  200 GB | we can delete other paritions to upgrade OS but preserve this, contains VM snapshots etc! |
# | sdaX | remaining | ~190 GB | unallocated as of now, perhaps install centos/windows or make it as another data parition |

# sda1   - primary
# sda5-8 - extended

########## Hard Disk Partitioning Variable
HD=/dev/sda
DEVBOOT=/dev/sda1
DEVSWAP=/dev/sda5
DEVROOT=/dev/sda6
DEVHOME=/dev/sda7
DEVDATA=/dev/sda8

BOOT_SIZE=500
ROOT_SIZE=100000
SWAP_SIZE=6000
HOME_SIZE=2000
DATA_SIZE=200000

# Partitions file system
BOOT_FS=ext4
HOME_FS=ext4
ROOT_FS=ext4
DATA_FS=ext4

######## Auxiliary variables. THIS SHOULD NOT BE ALTERED
BOOT_START=1
BOOT_END=$(($BOOT_START+$BOOT_SIZE))

SWAP_START=$BOOT_END
SWAP_END=$(($SWAP_START+$SWAP_SIZE))

ROOT_START=$SWAP_END
ROOT_END=$(($ROOT_START+$ROOT_SIZE))

HOME_START=$ROOT_END
HOME_END=$(($HOME_START+$HOME_SIZE))

DATA_START=$HOME_END
DATA_END=$(($DATA_START+$DATA_SIZE))

#### Partitioning
echo "HD Initialization"
# Set the partition table to MS-DOS type 
parted -s $HD mklabel msdos &> /dev/null

# Remove any older partitions
parted -s $HD rm 1 &> /dev/null
parted -s $HD rm 2 &> /dev/null
parted -s $HD rm 3 &> /dev/null
parted -s $HD rm 4 &> /dev/null

# Create boot partition
echo "Create boot partition"
parted -s $HD mkpart primary $BOOT_FS $BOOT_START $BOOT_END 1>/dev/null
parted -s $HD set 1 boot on 1>/dev/null

# Create the extended parition
parted -s $HD mkpart extended $SWAP_START $DATA_END

# Create swap partition
echo "Create swap partition"
parted -s $HD mkpart logical linux-swap $SWAP_START $SWAP_END 

# Create root partition
echo "Create root partition"
parted -s $HD mkpart logical $ROOT_FS $ROOT_START $ROOT_END 

# Create home partition
echo "Create home partition"
parted -s $HD mkpart logical $HOME_FS $HOME_START $HOME_END

echo "Creating data partition"
parted -s $HD mkpart logical $DATA_FS $DATA_START $DATA_END


# Formats the root, home and boot partition to the specified file system
echo "Formating boot partition"
mkfs.$BOOT_FS $DEVBOOT -L Boot 1>/dev/null
echo "Formating root partition"
mkfs.$ROOT_FS $DEVROOT -L Root 1>/dev/null
echo "Formating home partition"
mkfs.$HOME_FS $DEVHOME -L Home 1>/dev/null
echo "Formating data parition"
mkfs.$DATA_FS $DEVDATA -L Data 1>/dev/null

# Initializes the swap
echo "Formating swap partition"
mkswap $DEVSWAP
swapon $DEVSWAP


echo "Mounting partitions"
# mounts the root partition
mount $DEVROOT /mnt
# mounts the boot partition
mkdir /mnt/boot
mount $DEVBOOT /mnt/boot
# mounts the home partition
mkdir /mnt/home
mount $DEVHOME /mnt/home

wget https://goo.gl/gfPFgb -O base_install.sh
chmod +x base_install.sh

echo "Partitioning and mounting is done. Downloaded base_install.sh too."
