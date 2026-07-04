#!/bin/bash
PREV_TOTAL=0
PREV_IDLE=0

while true; do
  # 1. RAM (%)
  RAM=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')

  # 2. CPU (%)
  CPU_LINE=$(head -n 1 /proc/stat)
  IDLE=$(echo "$CPU_LINE" | awk '{print $5}')
  TOTAL=$(echo "$CPU_LINE" | awk '{for(i=2;i<=NF;i++) t+=$i; print t}')
  
  if [ "$PREV_TOTAL" -eq 0 ]; then
    CPU=0
  else
    DIFF_IDLE=$((IDLE - PREV_IDLE))
    DIFF_TOTAL=$((TOTAL - PREV_TOTAL))
    if [ "$DIFF_TOTAL" -gt 0 ]; then
        CPU=$((100 * (DIFF_TOTAL - DIFF_IDLE) / DIFF_TOTAL))
    else
        CPU=0
    fi
  fi
  PREV_TOTAL=$TOTAL
  PREV_IDLE=$IDLE

  # 3. Temperatura (°C)
  TEMP=0
  # Busca primero en hwmon (Ryzen/Intel coretemp) y luego en thermal_zone
  TEMP_FILE=$(find /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -n 1)
  if [ -n "$TEMP_FILE" ]; then
    TEMP=$(cat "$TEMP_FILE")
  elif [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
  fi
  TEMP=$((TEMP / 1000))

  # Imprime un formato limpio: "CPU,RAM,TEMP"
  echo "$CPU,$RAM,$TEMP"
  
  sleep 2
done