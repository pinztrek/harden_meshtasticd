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
# Use 0 for false, 1 for true for easier arithmetic checks
MESH="N"
SANEMESH=false
NEBRA=false
MESHTOAD=false
NEBRAHAT_1W=false
NEBRAHAT_2W=false
GPS=false
NOREBOOT=false
OWNER_NAME="" 
POSITIONAL_ARGS=()

# Function to display usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -m | --mesh        : Install mesh networking."
    echo "  -o | --owner        : Send the nodename (owner)
    echo "  	 --noreboot    : Do not perform a reboot after script execution."
    echo "  -r | --readonly    : Mount root filesystem as read-only."
    echo "  -s | --sanemesh    : Set sane mesh defaults for the US region."
    echo "  -t | --toad        : Set mesh config to use a meshtoad."
    echo "       --nebra       : Install mesh, do nebra setup and set to sane US defaults"
    echo "       --nebrahat   : Set mesh config to use a NebraMesh HAT."
    echo "       --nebrahat_2W   : Set mesh config to use a NebraMesh 2W HAT."
    echo "  -g | --gps         : Set mesh config to use a GPS."
    echo "  -h | --help        : Display this help message."
    exit 2
}

# --- Function to Query User for Yes/No Input ---
# Usage: ask_yes_no "Your prompt message?" "default_answer (y/n)"
# Returns: 0 (true) if 'y' or 'yes', 1 (false) otherwise.
ask_yes_no() {
    local prompt_message="$1"
    local default_answer="$2" # Expected to be 'y' or 'n' (case-insensitive)
    local user_input

    # Normalize default answer for display
    local display_default="[Y/n]"
    if [[ "$default_answer" =~ ^[Nn]$ ]]; then
        display_default="[y/N]"
    fi

    # Loop until valid input is received
    while true; do
        read -p "$prompt_message $display_default: " user_input
        # Apply default if user input is empty
        user_input=${user_input:-$default_answer}
        # Convert input to lowercase for robust comparison
        user_input_lower=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

        case "$user_input_lower" in
            y|yes)
                return 0 # True
                ;;
            n|no)
                return 1 # False
                ;;
            *)
                echo "Invalid input. Please enter 'y' (yes) or 'n' (no)." >&2
                ;;
        esac
    done
}

# Process command-line arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        # Short options
        -r|--readonly)
            RO_ROOT=true 
            shift # Remove param from processing
            echo "We will make the root FS read only if possible"
            ;;
        -m|--mesh)
            MESH=Y 
            shift # Remove param from processing
            echo "We will install meshtasticd"
            ;;
        -s|--sanemesh)
            SANEMESH=true
            MESH=Y # Implied by selection of this option
            shift # Remove param from processing
            echo "We will set sane mesh defaults for the US"
            ;;
        -n|--nebra)
            NEBRA=true
            MESH=Y # Implied by selection of this option
            SANEMESH=true # Implied US usage
            shift # Remove param from processing
            echo "We will set sane mesh defaults for the US" 
            ;;

        -t|--toad)
            MESHTOAD=true
            MESH=Y # Implied by selection of this option
            shift # Remove param from processing
            echo "We will set mesh config to use a meshtoad"
            ;;

        --nebrahat)
            NEBRAHAT_1W=true
            MESH=Y # Implied by selection of this option
            shift # Remove param from processing
            echo "We will set mesh config to use a NebraMesh hat" 
            ;;

        --nebrahat_2W)
            NEBRAHAT_2W=true
            MESH=Y # Implied by selection of this option
            shift # Remove param from processing
            echo "We will set mesh config to use a NebraMesh 2W hat"
            ;;

        -g|--gps)
            GPS=true
            shift # Remove param from processing
            echo "We will set mesh config to use a GPS"
            ;;
        --noreboot)
            NOREBOOT=true # Set the flag to 0 (false)
            shift # Remove param from processing
            echo "We will not reboot when complete"
            ;;
        -o|--owner) # nodename owner option
            if [[ -n "$2" && "$2" != -* ]]; then # Check if the next argument exists and is not another option
                OWNER_NAME="$2"
                shift 2 # Shift twice: once for the option, once for its argument
                echo "Owner name set to: $OWNER_NAME"
            else
                echo "Error: Option '$1' requires an argument." >&2
                usage # Display usage and exit
            fi
            ;;

        # Help option
        -h|--help)
            usage
            ;;
        # Catch all for unknown options or arguments
        -*)
            echo "Error: Unknown option '$1'" >&2
            exit 1
            ;;
        *) # Positional arguments
            POSITIONAL_ARGS+=("$1")
            shift # Remove the positional argument
            ;;
    esac
done


# Source error handling, leave this in place
set -e

#source /common.sh # Commented out, ensure /common.sh exists if uncommented
#install_cleanup_trap # Commented out, ensure defined if uncommented

### noninteractive Check
if [ -z "${DEBIAN_FRONTEND}" ]; then
    export DEBIAN_FRONTEND=noninteractive
fi

# JAB add root check, must be sudo'd
# Example root check:
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root or with sudo." >&2
    exit 1
fi


# JAB install needed scripts, assume git clone and script started from that dir
# usr/local
#unpack filesystem/usr/local/sbin/ /usr/local/sbin/ root

# JAB tune this later, requires use of ASL3 code
## Cleanup old kernels first, minimize size and number of DKMS builds needed
#/usr/local/sbin/minimize-kernels \
#       $(grep VERSION_CODENAME /etc/os-release | awk 'BEGIN {FS="="};{print $2}')

# JAB replace with meshtasticd repos, use same as for balena
## Install AllStarLink Repo
#wget -O/tmp/asl-apt-repos.deb12_all.deb \
#             https://repo.allstarlink.org/public/asl-apt-repos.deb12_all.deb
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
#             vim-nox


if [[ "`grep zram /etc/fstab`" ]]; then
    echo "Script has already run, skip volume and zram setup"
else
	# Do main system setup

	# Setup active dirs which do not need persistance as tmpfs
	cat - >> /etc/fstab <<EOF

tmpfs    /tmp            tmpfs    defaults,noatime,nosuid,nodev,noexec,mode=1777,size=128M 0 0
tmpfs    /var/tmp        tmpfs    defaults,noatime,nosuid,nodev,noexec,mode=1777,size=128M 0 0
# /opt/zram holds bind points and must be rw
tmpfs    /opt/zram       tmpfs    defaults,noatime,nosuid,nodev,noexec,mode=1777,size=15M 0 0
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
	sed -i "/$TARGET_LINE/a\\
	    $LINE_TO_ADD" "$FILE" # Quote $FILE for safety

	# Don't need these running
	for service in bluetooth ModemManager
	do
	    systemctl stop "$service" # Quote $service for safety
	    systemctl disable "$service" # Quote $service for safety
	done

	for service in systemd-logind systemd-timesyncd
	do
	    # restart them so they will use the new tmp
	    systemctl restart "$service" # Quote $service for safety
	done

	# Disable the auto apt stuff
	systemctl mask man-db.timer
	systemctl mask apt-daily.timer
	systemctl mask apt-daily-upgrade.timer

	echo "sudo mount -o remount,ro / ; sudo mount -o remount,ro /boot/firmware" >> /etc/bash.bash_logout

	# Deal with resolv.conf
	echo "Deal with resolv.conf"
	# Ensure the directory exists before copying
	mkdir -p /etc/NetworkManager/conf.d
	cp /etc/NetworkManager/NetworkManager.conf /etc/NetworkManager/conf.d/NetworkManager.conf # Ensure target filename is explicit
	FILE="/etc/NetworkManager/conf.d/NetworkManager.conf"
	LINE_TO_ADD="rc-manager=file"
	# now do the replacement
	sed -i '/\[main\]/a\\
	'"$LINE_TO_ADD" "$FILE" # Quote $FILE for safety

	sudo mv /etc/resolv.conf /var/run/resolv.conf && sudo ln -s /var/run/resolv.conf /etc/resolv.conf


	# Get and install zram-config

	REPO_OWNER="ecdye"
	REPO_NAME="zram-config"

	echo "Downloading zram-config"

	# use brute force to get zram for now - ensure it's downloaded to the temp dir
	wget -O "zram-config-v1.7.0.tar.lz" https://github.com/ecdye/zram-config/releases/download/v1.7.0/zram-config-v1.7.0.tar.lz

	# Fetch information for the latest release (original commented out block)
	# API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
	# DOWNLOAD_URL=$(curl -s "$API_URL" | \
	#                jq -r '.assets[] | select(.name | startswith("zram-config-") and endswith(".tar.lz")) | .browser_download_url' | head -n 1) # Added head -n 1 in case multiple match
	# echo "Fetching latest release information from: $DOWNLOAD_URL"
	# temporary disable till can sort
	# curl -s -O $DOWNLOAD_URL # This would download to current dir, not temp_zram_dir

	# Now install the package
	tar -xf zram-config-v1.7.0.tar.lz --strip-components=1 

	# relocate the zram log to allow ro filesystem (can't be in zram itself)
	# Use a temporary file for sed output and then move it
	sed -i "s_/usr/local/share/zram-config/log_/run_" "zram-config"  

	# JAB remove this once m*d installed
	mkdir -p /var/lib/meshtasticd
	# add dirs to ztab
	cat - >> ztab <<EOF

# dir    alg          mem_limit         disk_size         target_dir        bind_dir
dir    lzo-rle      50M               150M              /var/lib/meshtasticd      /mesh.bind
EOF

	# Run install from the extracted directory
	bash ./install.bash
	bash ./install.bash sync



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
fi # End of main system setup

if [[ -e harden_meshtasticd && -d harden_meshtasticd ]]; then
	rm -rf harden_meshtasticd.last
	mv harden_meshtasticd harden_meshtasticd.last
fi
# get the rest of the files for future usage
git clone https://github.com/pinztrek/harden_meshtasticd # Consider cloning to a specific path

# Rest of script is run from the cloned git dir structure
cd harden_meshtasticd


# Ask about meshtasticd installation

if [[ ! "$MESH" ]]; then
	if  ask_yes_no "Do you want to install meshtasticd?" "$MESH"; then
	    MESH=Y
	fi
fi
if [[ ! "`which meshtastic`" && "$MESH" ]]; then
    echo "Proceeding with meshtasticd install."
    pwd
    # Ensure mesh.sh exists and is executable, and handle its execution carefully
    # If mesh.sh is meant to be sourced, use '.'
    # If it's meant to be executed as a separate script, use 'bash mesh.sh' or './mesh.sh'
    # For a hardening script, executing it as a sub-process might be safer.
    if [[ -f "./mesh.sh" ]]; then
        bash ./mesh.sh # Execute as a sub-process
        if [[ -x /usr/local/bin/meshtastic ]]; then
            if [[ $OWNER_NAME ]]; then
                # set the nodename
                meshtastic --set-owner "$OWNER_NAME"
            else
                # Otherwise use hostname
                meshtastic --set-owner "`cat /etc/hostname`"
            fi
        fi
    else
        echo "Error: mesh.sh not found in the current directory.`pwd`" >&2
        exit 1
    fi
fi # End of mesh install, now check for mesh option if mesh is installed
if [[ "`which meshtastic`" ]]; then
    MD_DIR="/etc/meshtasticd/"
    # note these are checking for true/false, thus the single [
    if [ "$MESHTOAD" ]; then
        echo "Setting Radio to Meshtoad"
        rm -f config.d/*
        cp $MD_DIR/available.d/lora-usb-meshtoad-e22.yaml $MD_DIR/config.d
        cfg_device="meshtoad"
    fi

    if [ "$NEBRAHAT_1W" ]; then
        echo "Setting Radio to NebraHat_1W"
        rm -f $MD_DIR/config.d/*
        cp $MD_DIR/available.d/NebraHat_1W.yaml $MD_DIR/config.d
        cfg_device="NebraHat_1W"
    fi

    if [ "$NEBRAHAT_2W" ]; then
        echo "Setting Radio to NebraHat_2W"
        rm -f $MD_DIR/config.d/*
        cp $MD_DIR/available.d/NebraHat_2W.yaml $MD_DIR/config.d
        cfg_device="NebraHat_2W"
    fi
    if [ "$SANEMESH" ]; then
        if [[ -f /usr/local/bin/sane_radio_US.sh ]]; then
            echo "Setting radio to sane US settings"
            bash /usr/local/bin/sane_radio_US.sh
        else
            echo "Tried to set radio to sane, but failed"
        fi
    fi
fi # End of mesh options

# Now check for non mesh stuff

# If you intend RWROOT to be a boolean for read-write, initialize it as 0/1.
# Based on the option parsing, RO_ROOT=Y is set for read-only.
if [[ "$RO_ROOT" == "Y"  || $RO_ROOT == true ]]; then
    echo "Mounting root filesystem as read-only..."
    sudo mount -o remount,ro /
    sudo mount -o remount,ro /boot/firmware # Assuming /boot/firmware is your boot partition
fi

# Final reboot check based on REBOOT_FLAG
if (( NOREBOOT )); then
    echo "Reboot suppressed by --noreboot option."
else
    echo "Rebooting in 5 seconds..."
    sleep 5
    #sudo reboot
fi

echo "harden_meshtasticd finished."

