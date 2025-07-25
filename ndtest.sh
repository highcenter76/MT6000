#!/bin/sh

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BRIGHT_BLUE='\033[1;34m'
BRIGHT_WHITE='\033[1;37m'
DIM='\033[2m'
BRIGHT_CYAN='\033[1;36m'
BRIGHT_MAGENTA='\033[1;35m'
RESET='\033[0m'
BOLD='\033[1m'

# Fetch homepage HTML
if command -v wget >/dev/null 2>&1; then
    PAGE=$(wget -qO- "https://test.nextdns.io/")
elif command -v curl >/dev/null 2>&1; then
    PAGE=$(curl -s "https://test.nextdns.io/")
else
    echo -e "${RED}Error: wget or curl required.${RESET}"
    exit 1
fi

# Extract backend endpoint URL
ENDPOINT=$(echo "$PAGE" | grep -oE "https://[a-zA-Z0-9.-]+\.test\.nextdns\.io/" | head -n 1)

if [ -z "$ENDPOINT" ]; then
    echo -e "${RED}Error: Could not auto-detect endpoint.${RESET}"
    exit 1
fi

# Fetch JSON diagnostics
if command -v wget >/dev/null 2>&1; then
    RESULT=$(wget -qO- "$ENDPOINT")
elif command -v curl >/dev/null 2>&1; then
    RESULT=$(curl -s "$ENDPOINT")
else
    echo -e "${RED}Error: wget or curl required.${RESET}"
    exit 1
fi

# Get values for custom coloring logic
STATUS=$(echo "$RESULT" | grep '"status"' | sed -E 's/.*"status": *"?([^",}]*)"?[,]?.*/\1/')
PROTOCOL=$(echo "$RESULT" | grep '"protocol"' | sed -E 's/.*"protocol": *"?([^",}]*)"?[,]?.*/\1/')
PROFILE=$(echo "$RESULT" | grep '"profile"' | sed -E 's/.*"profile": *"?([^",}]*)"?[,]?.*/\1/')
SERVER=$(echo "$RESULT" | grep '"server"' | sed -E 's/.*"server": *"?([^",}]*)"?[,]?.*/\1/')
CLIENT=$(echo "$RESULT" | grep '"client"' | sed -E 's/.*"client": *"?([^",}]*)"?[,]?.*/\1/')
SRCIP=$(echo "$RESULT" | grep '"srcIP"' | sed -E 's/.*"srcIP": *"?([^",}]*)"?[,]?.*/\1/')
DESTIP=$(echo "$RESULT" | grep '"destIP"' | sed -E 's/.*"destIP": *"?([^",}]*)"?[,]?.*/\1/')
ANYCAST=$(echo "$RESULT" | grep '"anycast"' | sed -E 's/.*"anycast": *"?([^",}]*)"?[,]?.*/\1/')
CLIENTNAME=$(echo "$RESULT" | grep '"clientName"' | sed -E 's/.*"clientName": *"?([^",}]*)"?[,]?.*/\1/')
DEVICENAME=$(echo "$RESULT" | grep '"deviceName"' | sed -E 's/.*"deviceName": *"?([^",}]*)"?[,]?.*/\1/')
DEVICEID=$(echo "$RESULT" | grep '"deviceID"' | sed -E 's/.*"deviceID": *"?([^",}]*)"?[,]?.*/\1/')

# Custom color logic
if [ "$STATUS" = "ok" ]; then
    STATUS_COLOR="$GREEN"
else
    STATUS_COLOR="$RED"
fi

if [ "$PROTOCOL" = "DOT" ]; then
    PROTOCOL_COLOR="$GREEN"
else
    PROTOCOL_COLOR="$RED"
fi

PROFILE_COLOR="$DIM"
SRCIP_COLOR="$BRIGHT_WHITE"
DESTIP_COLOR="$DIM"
CLIENTNAME_COLOR="$DIM"
DEVICENAME_COLOR="$BRIGHT_MAGENTA"    # Updated to bright magenta
DEVICEID_COLOR="$DIM"
SERVER_COLOR="$BRIGHT_CYAN"           # Updated to bright cyan

# Pretty-print fields with custom colors
echo -e "${BOLD}${CYAN}NextDNS Diagnostics:${RESET}"
echo -e "${CYAN}====================${RESET}"
echo -e "${CYAN}Status:        ${RESET}${STATUS_COLOR}${STATUS}${RESET}"
echo -e "${CYAN}Protocol:      ${RESET}${PROTOCOL_COLOR}${PROTOCOL}${RESET}"
echo -e "${CYAN}Profile ID:    ${RESET}${PROFILE_COLOR}${PROFILE}${RESET}"
echo -e "${CYAN}Server:        ${RESET}${SERVER_COLOR}${SERVER}${RESET}"
echo -e "${CYAN}Client IP:     ${RESET}${CLIENT}${RESET}"
echo -e "${CYAN}Source IP:     ${RESET}${SRCIP_COLOR}${SRCIP}${RESET}"
echo -e "${CYAN}Destination IP:${RESET}${DESTIP_COLOR}${DESTIP}${RESET}"
echo -e "${CYAN}Anycast:       ${RESET}${YELLOW}${ANYCAST}${RESET}"
echo -e "${CYAN}Client Name:   ${RESET}${CLIENTNAME_COLOR}${CLIENTNAME}${RESET}"
echo -e "${CYAN}Device Name:   ${RESET}${DEVICENAME_COLOR}${DEVICENAME}${RESET}"
echo -e "${CYAN}Device ID:     ${RESET}${DEVICEID_COLOR}${DEVICEID}${RESET}"
echo -e "${CYAN}====================${RESET}"
