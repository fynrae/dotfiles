#!/bin/bash

options="Update Location"
choice=$(echo -e "$options" | tofi --prompt-text "TOOLBOX: ") 

case "$choice" in
	"Update Location")
		LOC=$(curl -s https://ipinfo.io/loc)
		LAT=$(echo $LOC | cut -d, -f1)
		LON=$(echo $LOC | cut -d, -f2)

		if [[ "$LAT" =~ ^[0-9.-]+$ ]]; then
			echo "LAT=$LAT" > ~/.cache/location_conf
			echo "LON=$LON" >> ~/.cache/location_conf
			
			pkill wlsunset
			wlsunset -l $LAT -L $LON -t 4000 -T 6500 &

			notify-send "Location Updated" "Saved $LAT, $LON"
		else
			notify-send "Error" "Could not fetch location" -u low
		fi
		;;
esac
