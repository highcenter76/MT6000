#!/bin/sh

PING_JSON=$(wget -qO- 'https://router.nextdns.io/?source=ping')
CURRENT_POP=$(wget -qO- 'https://router.nextdns.io/?source=test' | grep -Eo '"hostname":"[^"]+"' | cut -d'"' -f4 | sed 's/^ipv4-//;s/-[0-9]\+\.edge\.nextdns\.io$//')

echo "NextDNS Ping Diagnostics (by PoP)"
echo "=============================="
echo "Legend: ■ = PoP in use"
echo "--------------------------------"

TMPFILE=$(mktemp)

echo "$PING_JSON" | sed 's/\[{/{/g; s/},{/}\
{/g; s/}]/}/g' | while read line; do
    POP=$(echo "$line" | grep -Eo '"pop":"[^"]+"' | cut -d'"' -f4)
    SERVER=$(echo "$line" | grep -Eo '"server":"[^"]+"' | cut -d'"' -f4)
    HOST="${SERVER}.edge.nextdns.io"

    IP=$(nslookup "$HOST" 2>/dev/null | grep 'Address 1:' | awk '{print $3; exit}')
    LAT="99999"
    if [ -n "$IP" ]; then
        PING_OUT=$(ping -c 1 -w 1 "$IP" 2>&1)
        LAT=$(echo "$PING_OUT" | grep 'time=' | sed 's/.*time=\([0-9\.]*\) ms.*/\1/')
        [ -z "$LAT" ] && LAT="99999"
    fi

    # Tab-separated for reliable sort
    echo -e "$POP\t$LAT\t$SERVER" >> "$TMPFILE"
done

# Find best server per PoP, sort by latency
awk -F'\t' '
{
    pop=$1; lat=$2; server=$3;
    if (!(pop in minlat) || lat+0 < minlat[pop]+0) {
        minlat[pop]=lat;
        minserver[pop]=server;
    }
}
END {
    for (pop in minlat) {
        print minlat[pop], pop, minserver[pop];
    }
}
' "$TMPFILE" | sort -n | while read LAT POP SERVER; do
    [ "$POP" = "$CURRENT_POP" ] && MARK="■" || MARK=" "
    [ "$LAT" = "99999" ] && LAT="n/a"
    printf "%s %-14s %8s ms  (%s)\n" "$MARK" "$POP" "$LAT" "$SERVER"
done

rm -f "$TMPFILE"

echo "=============================="
