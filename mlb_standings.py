#!/usr/bin/env python3
import statsapi

def pct_to_float(pct_str):
    try:
        return float(pct_str)
    except:
        return 0.0

def get_nl_central(season="2025"):
    """Fetch and return the NL Central teamRecords list for the given season."""
    data = statsapi.get("standings", {"leagueId": 104, "season": season})
    nl_central = next(
        (rec for rec in data.get("records", [])
         if rec.get("division", {}).get("id") == 205),
        None
    )
    if not nl_central:
        raise RuntimeError("Could not find NL Central (divisionId=205)")
    return nl_central["teamRecords"]

def get_top5_overall(season="2025", top_n=5):
    """Fetch both leagues, flatten, and return the top N by pct for the given season."""
    all_recs = []
    for league_id in (103, 104):  # 103=AL, 104=NL
        data = statsapi.get("standings", {"leagueId": league_id, "season": season})
        for div_rec in data.get("records", []):
            # For division name only if needed elsewhere
            for tr in div_rec.get("teamRecords", []):
                pct_str = (
                    tr.get("winningPercentage")
                    or tr.get("winningPct")
                    or tr.get("leagueRecord", {}).get("pct")
                    or "0.000"
                )
                all_recs.append({
                    "team":    tr["team"]["name"],
                    "wins":    tr["wins"],
                    "losses":  tr["losses"],
                    "pct_str": pct_str,
                })
    # Sort descending by pct, take top N
    all_recs.sort(key=lambda x: pct_to_float(x["pct_str"]), reverse=True)
    return all_recs[:top_n]

def print_table_nlcentral(records, season="2025"):
    print(f"NL Central Standings ({season})")
    # Team:25 chars, W:3, L:3, GB:5
    print(f"{'Team':25s} {'W':>3s} {'L':>3s} {'GB':>5s}")
    for tr in records:
        team = tr["team"]["name"]
        w    = tr["wins"]
        l    = tr["losses"]
        gb   = tr.get("gamesBack", "N/A")
        print(f"{team:25s} {w:3d} {l:3d} {gb:>5s}")
    print()

def print_table_top5(records, season="2025"):
    print(f"Top {len(records)} MLB Teams by Wins/Losses (Season {season})")
    # Rank:4, Team:25, W:3, L:3, GB:5
    print(f"{'Rank':>4s} {'Team':25s} {'W':>3s} {'L':>3s} {'GB':>5s}")

    # Leader's record for GB calculations
    leader = records[0]
    lw, ll = leader["wins"], leader["losses"]

    def compute_gb(w, l):
        # ((leader_wins - w) + (l - leader_losses)) / 2
        return ((lw - w) + (l - ll)) / 2.0

    for idx, r in enumerate(records, start=1):
        if idx == 1:
            gb_str = "-"
        else:
            gb_str = f"{compute_gb(r['wins'], r['losses']):.1f}"
        print(
            f"{idx:4d} "
            f"{r['team']:25s} "
            f"{r['wins']:3d} "
            f"{r['losses']:3d} "
            f"{gb_str:>5s}"
        )
    print()

def main():
    season = "2025"
    nl_cent = get_nl_central(season)
    top5    = get_top5_overall(season, top_n=5)

    print_table_nlcentral(nl_cent, season)
    print_table_top5(top5, season)

if __name__ == "__main__":
    main()