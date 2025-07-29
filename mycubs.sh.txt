#!/bin/sh
#
# Chicago Cubs Standings
# Fetch:
#  1) NL Central standings (division.id == 205)
#  2) Top 5 overall MLB, with correct GB vs. the leader
# Format into aligned columns via awk.
#
# Requires: curl, jq, awk
#

# Season set to current year
SEASON=$(date +%Y)
API="https://statsapi.mlb.com/api/v1/standings"
PARAMS="?season=${SEASON}&standingsTypes=regularSeason&leagueId=103,104"

# Single fetch for everything
JSON=$(curl -s "${API}${PARAMS}")

# NL Central
echo "=== NL Central Standings (${SEASON} Regular Season) ==="
echo "${JSON}" |
  jq -r '
    .records[]
    | select(.division.id == 205)
    | .teamRecords
    | sort_by(.wins) | reverse
    | .[]
    | [.team.name, "\(.wins)-\(.losses)", "GB:\(.gamesBack // "-")"]
    | @tsv
  ' |
  awk -F'\t' '{ printf "%-24s %7s %-7s\n", $1, $2, $3 }'

echo

# Top 5 Overall MLB with correct GB calculation
echo "=== Top 5 Overall MLB (${SEASON} Regular Season) ==="
echo "${JSON}" |
  jq -r '
    # Build sorted top-5 array
    [ .records[].teamRecords[] ]
    | sort_by(.wins) | reverse
    | .[0:5] as $top5
    # Leader is the first element
    | $top5[0] as $leader
    # Emit each team with calculated GB
    | $top5[]
    | [
        .team.name,
        "\(.wins)-\(.losses)",
        (
          # GB = ((leader.wins - team.wins) + (team.losses - leader.losses)) / 2
          "GB:\( (( $leader.wins - .wins ) + ( .losses - $leader.losses ))/2 )"
        )
      ]
    | @tsv
  ' |
  awk -F'\t' '{ printf "%-24s %7s %-7s\n", $1, $2, $3 }'
