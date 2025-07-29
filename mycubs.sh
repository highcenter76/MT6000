#!/bin/sh
#
# Chicago Cubs Standings
# Fetch:
#  1) NL Central standings (division.id == 205)
#  2) Top 5 overall MLB, sorted by computed GB
# Format into aligned columns via awk.
#
# Requires: curl, jq, awk
#

# Date set to current year
SEASON=$(date +%Y)
API="https://statsapi.mlb.com/api/v1/standings"
PARAMS="?season=${SEASON}&standingsTypes=regularSeason&leagueId=103,104"

# Fetch once
JSON=$(curl -s "${API}${PARAMS}")

# 1) NL Central
echo "=== NL Central Standings (${SEASON} Regular Season) ==="
echo "${JSON}" |
  jq -r '
    # grab only NL Central division teams, sort by wins desc, losses asc
    .records[]
    | select(.division.id == 205)
    | .teamRecords
    | sort_by(-.wins, .losses)
    as $all
    # leader is the first entry
    | $all[0] as $leader
    # build each record with numeric GB and formatted GB
    | $all
    | map({
        team: .team.name,
        wl: "\(.wins)-\(.losses)",
        gbNum: (
          (
            ( $leader.wins - .wins )
            + ( .losses - $leader.losses )
          ) / 2
        ),
        gb: (
          "GB:"
          + (
              (
                ( $leader.wins - .wins )
                + ( .losses - $leader.losses )
              ) / 2
            | if (.|floor) == . then
                "\(floor)"
              else
                tostring
              end
            )
        )
      })
    # sort by the numeric GB field ascending
    | sort_by(.gbNum)
    # output as TSV
    | .[]
    | [ .team, .wl, .gb ]
    | @tsv
  ' |
  awk -F'\t' '{ printf "%-24s %7s %-7s\n", $1, $2, $3 }'

echo

# 2) Top 5 Overall MLB, sorted by computed GB
echo "=== Top 5 Overall MLB (${SEASON} Regular Season) ==="
echo "${JSON}" |
  jq -r '
    # gather all teamRecords, sort by wins desc, pick top 5
    [ .records[].teamRecords[] ]
    | sort_by(-.wins, .losses)
    | .[0:5] as $top5
    # leader is the best of those
    | $top5[0] as $leader
    # map into objects with numeric GB and formatted GB
    | $top5
    | map({
        team: .team.name,
        wl: "\(.wins)-\(.losses)",
        gbNum: (
          (
            ( $leader.wins - .wins )
            + ( .losses - $leader.losses )
          ) / 2
        ),
        gb: (
          "GB:"
          + (
              (
                ( $leader.wins - .wins )
                + ( .losses - $leader.losses )
              ) / 2
            | tostring
            )
        )
      })
    # sort by computed GB ascending
    | sort_by(.gbNum)
    # output TSV
    | .[]
    | [ .team, .wl, .gb ]
    | @tsv
  ' |
  awk -F'\t' '{ printf "%-24s %7s %-7s\n", $1, $2, $3 }'
