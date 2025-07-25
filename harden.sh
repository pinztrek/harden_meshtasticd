#!/usr/bin/env bash
# harden.sh
# hardends a debian based system for meshtasticd usage
#
# Heavily influenced by Jason McCormick N8EI's 
# ASL3 start_chroot_script
# GPL V3
########

# Save params
# Default values for options
REBOOT=false
RESTART=false
NOMESH=false
RWROOT=false

# Function to display usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --reboot    : Perform a reboot after script execution."
    echo "  --restart   : Restart a service after script execution."
    echo "  --nomesh    : Disable mesh networking."
    echo "  --rwroot    : Mount root filesystem as read-write."
    echo "  --help      : Display this help message."
    exit 1
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --reboot)
            REBOOT=true
            ;;
        --restart)
            RESTART=true
            ;;
        --nomesh)
            NOMESH=true
            ;;
        --rwroot)
            RWROOT=true
            ;;
        --help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
    shift
done


# Example actions based on options
if $REBOOT; then
    echo "Performing reboot action..."
    # sudo reboot
fi

if $RESTART; then
    echo "Performing restart action..."
    # sudo systemctl restart your_service_name
fi

if $NOMESH; then
    echo "Disabling mesh networking..."
    # Commands to disable mesh networking
fi

if $RWROOT; then
    echo "Mounting root filesystem as read-write..."
    # sudo mount -o remount,rw /
fi

echo "Script finished."
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
apt install -y lunzip jq wget git
#apt install -y asl3 asl3-menu asl3-update-nodelist allmon3 asl3-pi-appliance \
	#vim-nox

# Setup active dirs which do not need persistance as tmpfs
cat - >> /etc/fstab <<EOF

tmpfs	/tmp		tmpfs	defaults,noatime,nosuid,nodev,noexec,mode=1777,size=128M 0 0
tmpfs	/var/tmp	tmpfs	defaults,noatime,nosuid,nodev,noexec,mode=1777,size=128M 0 0
# /opt/zram holds bind points and must be rw
tmpfs	/opt/zram	tmpfs	defaults,noatime,nosuid,nodev,noexec,mode=1777,size=15M 0 0
EOF

# Now activate the new ram tmp dirs
mv /tmp /tmp.old
mkdir -m 1777 /tmp
mount /tmp
mv /var/tmp /var/tmp.old
mkdir -m 1777 /var/tmp
mount /var/tmp
mkdir -p -m 1777 /opt/zram
mount /opt/zram

# Now we can get rid of the old tmp dirs
rm -rf /tmp.old /var/tmp.old 

# move key files/dirs to tmp to allow RO /
# JAB this needs more work, edit cfg file
rm -rf /var/spool #/etc/resolv.conf

rm -rf /var/lib/dhcp && ln -s /var/run /var/lib/dhcp
rm -rf /var/lib/dhcp5 && ln -s /var/run /var/lib/dhcp5
rm -rf /var/lib/sudo && ln -s /var/run /var/lib/sudo
# Comment this out if not using logrotate
#rm -rf /var/lib/logrotate && ln -s /var/run /var/lib/logrotate
rm -rf /var/lib/NetworkManager && ln -s /var/run /var/lib/NetworkManager
rm -rf /var/spool && ln -s /tmp /var/spool

# Deal with randomseed
echo "Deal with randomseed"

mv /var/lib/systemd/random-seed /tmp/systemd-random-seed && ln -s /tmp/systemd-random-seed /var/lib/systemd/random-seed
# create a copy of the service, this will override the default
cp /usr/lib/systemd/system/systemd-random-seed.service /etc/systemd/system
FILE="/etc/systemd/system/systemd-random-seed.service"
TARGET_LINE='RemainAfterExit=yes'
LINE_TO_ADD='ExecStartPre=/bin/echo "" >/tmp/systemd-random-seed'
# now do the replacement
sed -i "/$TARGET_LINE/a\
    $LINE_TO_ADD" $FILE

# Don't need these running
for service in bluetooth ModemManager
do
    systemctl stop $service
    systemctl disable $service
done

for service in systemd-logind  systemd-timesyncd
do
    # restart them so they will use the new tmp
    systemctl restart $service
done

# Disable the auto apt stuff
systemctl mask man-db.timer
systemctl mask apt-daily.timer
systemctl mask apt-daily-upgrade.timer

echo "sudo mount -o remount,ro / ; sudo mount -o remount,ro /boot/firmware" >> /etc/bash.bash_logout

# Deal with resolv.conf
echo "Deal with resolv.conf"
cp /etc/NetworkManager/NetworkManager.conf /etc/NetworkManager/conf.d
FILE="/etc/NetworkManager/conf.d/NetworkManager.conf"
LINE_TO_ADD="rc-manager=file"
# now do the replacement
sed -i '/\[main\]/a\
'"$LINE_TO_ADD" $FILE

sudo mv /etc/resolv.conf /var/run/resolv.conf && sudo ln -s /var/run/resolv.conf /etc/resolv.conf


# Get and install zram-config

REPO_OWNER="ecdye"
REPO_NAME="zram-config"

# use brute force to get zram for now
wget https://github.com/ecdye/zram-config/releases/download/v1.7.0/zram-config-v1.7.0.tar.lz

# Fetch information for the latest release
API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"

#DOWNLOAD_URL=$(curl -s "$API_URL" | \
               #jq -r '.assets[] | select(.name | startswith("zram-config-") and endswith(".tar.lz")) | .browser_download_url' | head -n 1) # Added head -n 1 in case multiple match

#echo "Fetching latest release information from: $DOWNLOAD_URL"
#temporary disable till can sort
#curl -s -O $DOWNLOAD_URL


# Now install the package
mkdir -p zram-config && tar -xf zram-config*.tar.lz --strip-components=1 --directory=zram-config
# relocate the zram log to allow ro filesystem (can't be in zram itself)
sed s_/usr\/local\/share/zram-config/log_/run_ ./zram-config/zram-config

# JAB remove this once m*d installed
mkdir -p /var/lib/meshtasticd
# add dirs to ztab
cat - >> ./zram-config/ztab <<EOF

# dir   alg             mem_limit       disk_size       target_dir      bind_dir
dir    lzo-rle         50M             150M            /var/lib/meshtasticd        /mesh.bind
EOF

./zram-config/install.bash
./zram-config/install.bash sync


cat - >> /etc/bash.bashrc <<EOF
#alias dir='dir --color=auto'
#alias egrep='egrep --color=auto'
#alias fgrep='fgrep --color=auto'
#alias grep='grep --color=auto'
alias ll='ls -l'
set -o vi
#alias ls='ls --color=auto'
alias rpi-ro='sudo sync ; sudo sync ; sudo sync ; sudo mount -o remount,ro / ; sudo mount -o remount,ro /boot'
alias rpi-rw='sudo mount -o remount,rw / ; sudo mount -o remount,rw /boot'
#alias vdir='vdir --color=auto'
EOF

# disable rfkill now
echo "disable rfkill now"
systemctl mask systemd-rfkill.socket
systemctl disable systemd-rfkill.service

# get the rest of the files for future usage
git clone https://github.com/pinztrek/harden_meshtasticd


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
