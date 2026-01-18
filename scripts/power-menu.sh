#!/bin/bash

options="Shutdown\nReboot\nSleep\nLogout\nLock\nSuspend"
choice=$(echo -e "$options" | tofi --prompt-text "POWER: ")

case "$choice" in
	Shutdown)
		systemctl poweroff
		;;
	Reboot)
		systemctl reboot
		;;
	Sleep)
		systemctl sleep
		;;
	Lock)
		swaylock -f
		;;
	Logout)
		swaymsg exit
		;;
	Suspend)
		systemctl suspend
		;;
esac
