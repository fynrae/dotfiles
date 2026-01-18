#!/bin/bash

if [ -f "$HOME/.cache/location_conf" ]; then 
	source $HOME/.cache/location_conf
else
	LAT="21.0"
	LON="105.8"
fi

pkill wlsunset
wlsunset -l $LAT -L $LON -t 4000 -T 6500 &
