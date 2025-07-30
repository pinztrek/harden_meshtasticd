# harden_meshtasticd

The meshtasticd subsystem running on SBC's like Raspberry Pi's are becoming more common. Typically debian based OS's like raspbian or Ubuntu are utilized, which is convenient due to their umbiquity. But Debian or similar by itself is not ready for unattended remote operation and specifically with some of the aspects of meshtasticd can create reliability issues. 

# Project Goals
There are several amateur related pi based systems which are hardened to improve reliability. Pi-star and Allstarlink 3 are two great examples, and longterm experience with both have demonstrated the advantages of their approaches. Likewise, longterm support of remote non-hardened debian systems have shown problem areas. This project intends to leverage known best practices from those projects and adverse experiences of the author with non hardended pi based systems.

## Address Known problem areas for Pi based debian systems
1. Address constant writes to the SD card which will destroy them over time
2. Clean up unneeded systems to minimize disk space
3. Minimize ram footprint to allow for use of ram based filesystems

## Allow usage of standard meshtastic debs, tools and typical file layout
3. Install meshtasticd and tools from the official repo
   
## Can be applied retroactively to a clean debian install (IE: No special image required)

## Allow use of standard debian update tools

## Facilitate nightly process restarts or similar for reliability

# Approach

* Script based tool to modify/tune a clean debian install to harden for long term meshtasticd usage
* Implement ram based filesystems for highly active filesystems (/tmp & /var/log) (Complete)
* Implement persistance for key log file snapshots and meshtasticd config/state files using zram-config (Complete)
* Relocate key system files/dirs to temp to allow RO FS (DHCP, etc) (in progress)
* Implement log rotation as needed for meshtasticd and related tools
* Implement systemd as needed for key processes (In Progress)
* Disable known processes which churn the disk (nightly apts downloads, etc)
* Implement cron based nightly restarts for the meshtasticd process at a configurable time
* Optionally implement periodic system reboots
* (Long term) Implement read only filesystems for /boot and any non-dynamic directories using standard raspbian approachs (pi-ro, pi-rw, etc) (In Progress, but is proving harder than initially thought)

# Installation
* Use raspberry_pi_imager to download Raspberry Pi OS Lite 64bit image. Make sure and set your login and network if needed.
* Boot the image, and log in
* Get the harden script and execute as root:
> wget -O harden.sh https://raw.githubusercontent.com/pinztrek/harden_meshtasticd/refs/heads/main/harden.sh<br>
> sudo bash ./harden.sh

* To install meshtasticd and set the radio to reasonable US defaults:
> wget -O harden.sh https://raw.githubusercontent.com/pinztrek/harden_meshtasticd/refs/heads/main/harden.sh<br>
> sudo bash ./harden.sh -m -s


# Command-Line Options

This script supports the following command-line options to control its behavior:

| **Short Form** | **Long Form** | **Argument** | **Description** |
| :--------- | :---------- | :------- | :----------------------------------------------------------------------- |
| `-m` | `--mesh` | None | Installs the Meshtastic daemon (`meshtasticd`). |
| `-o` | `--owner` | desired_name | sets the nodename |
| `-s` | `--sanemesh` | None | Applies sane default Meshtastic settings for the US region. <br>Triggers --mesh|
| `-n` | `--nebra` | None | (Future) Configures Meshtastic for a Nebra device with sane default settings for the US region. <br>Triggers --sanemesh as US usage is assumed|
| `-t` | `--toad` | None | (Future) Configures Meshtastic to use a Meshtoad device. <br>Triggers --mesh|
| | `--nebramesh` | None | (Future) Configures Meshtastic to use a NebraMesh HAT. <br>Triggers --mesh|
| `-g` | `--gps` | None | (Future) Configures Meshtastic to use a GPS module. |
| | `--noreboot` | None | (Future) Prevents the system from rebooting after script completion. |
| `-r` | `--readonly` | None | (Future) Configures the root filesystem to be read-only if supported. |
| `-h` | `--help` | None | Displays a help message with usage instructions and exits. |

# Notes and caveats
* The hostname is used as the default nodename. This can be changed via meshtastic CLI or set the hostname to be your desired nodename. 
* --sanemesh and similar may not work if no radio is installed (many CLI commands can cause a reboot of meshtasticd)
* The script is intended to be run just once. I've attempted to skip any sections damaged by a 2nd run, but 
it has not been extensively tested
* While the majority of streaming disk activity for subsystems like meshtasticd have been moved to ram and zram, some 
disk writes do still occur on the root FS. This is OK for EEMC based systems, but microSD will still have a finite life 
if run 7x24 for years. The longterm answer is having a read only root FS, which is in progress but not released yet. 

# Acknowledgements
Initial experience with pi-star on multiple DMR repeaters, and also AllstarLink 3 on repeaters led to understanding the approach they used. Both projects directly influenced this project's design, and some code fragments were utilzed from ASL3. 
