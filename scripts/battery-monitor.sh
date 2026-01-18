#!/usr/bin/env bash

BAT_PATH=/org/freedesktop/UPower/devices/battery_BAT0
AC_PATH=/org/freedesktop/UPower/devices/line_power_AC

print_status() {
  local capacity=$1
  local ac_status=$2

  if [ "$ac_status" == "true" ]; then
    echo "+${capacity}"
  else
    echo "${capacity}"
  fi

  if [ "$ac_status" == "false" ] && [ "$capacity" -le 15 ]; then
      if [ ! -f /tmp/bat_warned ]; then
          notify-send -u critical "Battery Low" "${capacity}% Remaining"
          touch /tmp/bat_warned
      fi
  else
      rm -f /tmp/bat_warned 2>/dev/null
  fi
}

PERC_FLOAT=$(gdbus call --system \
    --dest org.freedesktop.UPower \
    --object-path $BAT_PATH \
    --method org.freedesktop.DBus.Properties.Get org.freedesktop.UPower.Device Percentage \
    | grep -oE '[0-9]+(\.[0-9]+)?' | head -n1)

AC_STATE=$(gdbus call --system \
    --dest org.freedesktop.UPower \
    --object-path $AC_PATH \
    --method org.freedesktop.DBus.Properties.Get org.freedesktop.UPower.Device Online \
    | grep -oE 'true|false')

PERC_INT=${PERC_FLOAT%.*}
print_status "$PERC_INT" "$AC_STATE"

gdbus monitor --system --dest org.freedesktop.UPower |
while read -r line; do
  changed=0

  if [[ "$line" == *"Percentage"* ]]; then
    PERCENTAGE_FLOAT=$(echo "$line" | awk -F "Percentage" '{print $2}' | grep -oE '[0-9]+(\.[0-9]+)?' | head -n1)
    if [[ -n "$PERCENTAGE_FLOAT" ]]; then
      NEW_PERC_INT=${PERCENTAGE_FLOAT%.*}
      if [[ "$NEW_PERC_INT" != "$PERC_INT" ]]; then
          PERC_INT=$NEW_PERC_INT
          changed=1
      fi
    fi

  elif [[ "$line" == *"Online"* ]]; then
    NEW_AC_STATE=$(echo "$line" | grep -oE 'true|false')
    if [[ -n "$NEW_AC_STATE" ]] && [[ "$NEW_AC_STATE" != "$AC_STATE" ]]; then
        AC_STATE=$NEW_AC_STATE
        changed=1
    fi
  fi

  if [[ $changed -eq 1 ]]; then
    print_status "$PERC_INT" "$AC_STATE"
  fi
done
