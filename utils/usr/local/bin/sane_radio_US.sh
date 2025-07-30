#!/bin/bash
SANEYAML="/etc/meshtasticd/sane.yaml"

if [[ -f $SANEYAML && -s $SANEYAML ]]; then
	echo "Using $SANEYAML"
	meshtastic --configure $SANEYAML
else
	# no dist sane.yaml, do it manually. 
	SETTINGS="--set lora.region US --set lora.modem_preset LONG_FAST --ch-set-url https://meshtastic.org/e/#CgMSAQESCAgBOAFAA0gB --set device.rebroadcastMode 5"
	echo "Setting radio to usable US settings: $SETTINGS"
	meshtastic  $SETTINGS
fi
