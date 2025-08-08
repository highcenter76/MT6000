#!/usr/bin/env python3
# encoding=utf-8
# Reworked from https://github.com/macvk/dnsleaktest
# Thank you, macvk!

import os
import subprocess
import json
import socket
from platform import system as system_name
from subprocess import call as system_call
from urllib.request import urlopen

# ANSI escape codes for formatting
RESET = "\033[0m"
BOLD = "\033[1m"
UNDERLINE = "\033[4m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
CYAN = "\033[36m"

def ping(host: str) -> bool:
    """Ping a host and return True if reachable, False otherwise."""
    param = '-n' if system_name().lower() == 'windows' else '-c'
    command = ['ping', param, '1', host]
    with open(os.devnull, 'w') as fn:
        retcode = system_call(command, stdout=fn, stderr=subprocess.STDOUT)
    return retcode == 0

def get_hostname(ip: str) -> str:
    """Resolve an IP address to a hostname."""
    try:
        return socket.gethostbyaddr(ip)[0]
    except socket.herror:
        return "Unknown"

def print_dns_info(dns_server):
    """Print DNS server information in a boxed format."""
    dns_hostname = get_hostname(dns_server['ip'])
    print(f"{BOLD}{dns_server['ip']} -- {dns_hostname}{RESET}")
    if dns_server['country_name']:
        print(f"{dns_server['country_name']}")
    if dns_server['asn']:
        print(f"{dns_server['asn']}")
    if 'provider' in dns_server:
        print(f"{dns_server['provider']}")
    print("<><>" * 10)  # Separator line for clarity

try:
    response = urlopen("https://bash.ws/id")
    data = response.read().decode("utf-8")
except Exception as e:
    print(f"{RED}Error fetching leak ID: {e}{RESET}")
    exit(1)

leak_id = data.strip()  # Ensure no extra whitespace

# Ping hosts
print(f"{CYAN}Pinging hosts...{RESET}")
for x in range(10):
    ping_host = f"{x}.{leak_id}.bash.ws"
    ping(ping_host)

try:
    response = urlopen(f"https://bash.ws/dnsleak/test/{leak_id}?json")
    data = response.read().decode("utf-8")
    parsed_data = json.loads(data)
except Exception as e:
    print(f"{RED}Error fetching DNS leak data: {e}{RESET}")
    exit(1)
except json.JSONDecodeError:
    print(f"{RED}Error decoding JSON data.{RESET}")
    exit(1)

# Display IP information
print(f"\n{BOLD}{UNDERLINE}Your IP:{RESET}")
for dns_server in parsed_data:
    if dns_server['type'] == "ip":
        print(f"{dns_server['ip']}")
        if dns_server['country_name']:
            print(f"{dns_server['country_name']}")
        if dns_server['asn']:
            print(f"{dns_server['asn']}")
        if 'provider' in dns_server:
            print(f"{dns_server['provider']}")
        print()  # Add a blank line for separation

# Count DNS servers
servers = sum(1 for dns_server in parsed_data if dns_server['type'] == "dns")

if servers == 0:
    print(f"{YELLOW}No DNS servers found{RESET}")
else:
    print(f"\n{BOLD}{UNDERLINE}You use {servers} DNS servers:{RESET}")
    for dns_server in parsed_data:
        if dns_server['type'] == "dns":
            print_dns_info(dns_server)

# Conclusion
print(f"\n{BOLD}{UNDERLINE}Conclusion:{RESET}")
for dns_server in parsed_data:
    if dns_server['type'] == "conclusion" and dns_server['ip']:
        print(f"{BOLD}{dns_server['ip']}{RESET}")
