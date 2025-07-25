#!/bin/sh
#
# Interactive two-phase MTU finder
# Basic for use with BusyBox
# Now with COLOR
#

# ANSI escapes for color
ESC="\033["
RST="${ESC}0m"
BOLD="${ESC}1m"
C_RED="${ESC}31m"
C_GRN="${ESC}32m"
C_YEL="${ESC}33m"
C_BLU="${ESC}34m"
C_MAG="${ESC}35m"
C_CYN="${ESC}36m"
C_WHT="${ESC}37m"

# Default values
DEF_TARGET="8.8.8.8"
DEF_MAX=1500
DEF_MIN=68
DEF_STEP=10

# Prompt function: prints $1 then reads into $2, uses $3 if empty
prompt() {
  QUESTION="$1"
  VAR_NAME="$2"
  DEFAULT="$3"
  printf "${C_YEL}%s [${DEFAULT}]: ${RST}" "${QUESTION}"
  # read user input into a temp var
  read INPUT
  # if blank, use default
  if [ -z "$INPUT" ]; then
    eval "$VAR_NAME=\$DEFAULT"
  else
    eval "$VAR_NAME=\$INPUT"
  fi
}

# 1) Get user inputs
prompt "Target IP/Host"    TARGET "$DEF_TARGET"
prompt "Max MTU to try"    MAX    "$DEF_MAX"
prompt "Min MTU to try"    MIN    "$DEF_MIN"
prompt "Coarse step (-N)"  STEP1  "$DEF_STEP"

# Compute some constants
IP_HDR=20
ICMP_HDR=8

# Phase 1 header
printf "\n${BOLD}${C_CYN}=== Phase 1: Coarse Search ===${RST}\n"
printf "  Target: ${C_MAG}%s${RST}\n" "$TARGET"
printf "  Range : ${C_YEL}%d → %d${RST}\n" "$MAX" "$MIN"
printf "  Step  : ${C_YEL}-%d${RST}\n\n" "$STEP1"

coarse_ok=

for mtu in $(seq $MAX -$STEP1 $MIN); do
  payload=$(( mtu - IP_HDR - ICMP_HDR ))
  printf "\r${C_YEL}→ Trying MTU:%4d${RST} " "$mtu"
  if ping -c2 -s $payload $TARGET >/dev/null 2>&1; then
    coarse_ok=$mtu
    break
  fi
done

if [ -z "$coarse_ok" ]; then
  printf "\n${BOLD}${C_RED}✗ No success in coarse phase; exiting.${RST}\n"
  exit 1
fi
printf "\n${BOLD}${C_GRN}✔ Coarse OK = %d${RST}\n\n" "$coarse_ok"

# Phase 2 window
start=$(( coarse_ok + 1 ))
end=$(( coarse_ok + STEP1 - 1 ))
[ $end -gt $MAX ] && end=$MAX

# Phase 2 header
printf "${BOLD}${C_CYN}=== Phase 2: Fine Search ===${RST}\n"
printf "  Window: ${C_YEL}%d → %d${RST}\n" "$start" "$end"
printf "  Step  : ${C_YEL}+1${RST}\n\n"

last_ok=$coarse_ok

for mtu in $(seq $start 1 $end); do
  payload=$(( mtu - IP_HDR - ICMP_HDR ))
  printf "\r${C_BLU}→ Trying MTU:%4d${RST} " "$mtu"
  if ping -c2 -s $payload $TARGET >/dev/null 2>&1; then
    last_ok=$mtu
  else
    printf "\n${BOLD}${C_GRN}✔ Found exact MTU = %d bytes${RST}\n" "$last_ok"
    exit 0
  fi
done

# If no failure up to 'end', 'end' is MTU
printf "\n${BOLD}${C_GRN}✔ Found exact MTU = %d bytes${RST}\n" "$end"
exit 0
