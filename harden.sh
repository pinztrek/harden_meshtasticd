#!/usr/bin/env bash
# harden.sh
# hardends a debian based system for meshtasticd usage
#
# Heavily influenced by Jason McCormick N8EI's 
# ASL3 start_chroot_script
# GPL V3
########


# Source error handling, leave this in place
set -e

#source /common.sh
#install_cleanup_trap

### noninteractive Check
if [ -z "${DEBIAN_FRONTEND}" ]; then
    export DEBIAN_FRONTEND=noninteractive
fi

# JAB add root check, must be sudo'd


# JAB install needed scripts, assume git clone and script started from that dir
# usr/local
#unpack filesystem/usr/local/sbin/ /usr/local/sbin/ root

# JAB tune this later, requires use of ASL3 code
## Cleanup old kernels first, minimize size and number of DKMS builds needed
#/usr/local/sbin/minimize-kernels \
#	$(grep VERSION_CODENAME /etc/os-release | awk 'BEGIN {FS="="};{print $2}')

# JAB replace with meshtasticd repos, use same as for balena
## Install AllStarLink Repo
#wget -O/tmp/asl-apt-repos.deb12_all.deb \
	 #https://repo.allstarlink.org/public/asl-apt-repos.deb12_all.deb
#dpkg -i /tmp/asl-apt-repos.deb12_all.deb
#rm -f /tmp/asl-apt-repos.deb12_all.deb

## Do apt things
apt update
apt remove -y iptables exim4-base exim4-config exim4-daemon-light
apt autoremove -y
apt purge -y exim4-base exim4-config exim4-daemon-light
# JAB tune for meshtasticd and tools like logrotate, Log2Ram, etc
apt install -y lunzip jq wget
#apt install -y asl3 asl3-menu asl3-update-nodelist allmon3 asl3-pi-appliance \
	vim-nox

# Setup active dirs which do not need persistance as tmpfs
cat - >> /etc/fstab <<EOF

tmpfs	/tmp		tmpfs	defaults,noatime,nosuid,nodev,noexec,mode=1777,size=128M 0 0
tmpfs	/var/tmp	tmpfs	defaults,noatime,nosuid,nodev,noexec,mode=1777,size=128M 0 0
EOF

# Now activate the new ram tmp dirs
mv /tmp /tmp.old
mkdir -m 1777 /tmp
mount /tmp
mv /var/tmp /var/tmp.old
mkdir -m 1777 /var/tmp
mount /var/tmp




# Get and install zram-config
# JAB refine this to use latest automatically
wget https://github.com/ecdye/zram-config/releases/download/v1.7.0/zram-config-v1.7.0.tar.lz
#gh release download --repo ecdye/zram-config --pattern '*.tar.lz'
mkdir -p zram-config && tar -xf zram-config*.tar.lz --strip-components=1 --directory=zram-config

# JAB remove this once m*d installed
mkdir -p /var/lib/portduinio
# add dirs to ztab
cat - >> ./zram-config/ztab <<EOF

# dir   alg             mem_limit       disk_size       target_dir      bind_dir
dir    lzo-rle         50M             150M            /var/lib/portduinio        /portduinio.bind
EOF

./zram-config/install.bash
./zram-config/install.bash sync

exit  #-------------------------------------------------------------------

# Create motd & issue
#unpack filesystem/etc /etc
#echo "" > /etc/issue
#echo "" > /etc/issue.net

# Set Firstboot
#unpack filesystem/etc/systemd/system/ /etc/systemd/system/ root
#touch /asl3-first-boot-needed
#systemctl enable systemd-time-wait-sync.service
#systemctl enable asl3-firstboot
#systemctl enable asl3-firstboot-pkg-updates

# Disk IO minimization
rm -f /var/log/apache2/*
rm -rf /var/log/journal
rm -rf /var/log/asterisk/*

AST_UID=$(getent passwd asterisk | awk -F: '{print $3}')
AST_GID=$(getent passwd asterisk | awk -F: '{print $4}')

# Disable bluetooth for GPIO accessibility
echo "dtoverlay=disable-bt" >> /boot/firmware/config.txt
