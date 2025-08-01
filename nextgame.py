#!/usr/bin/env python3
"""
nextgame.py

Show Chicago Cubs games between two dates.

Usage:
  python3 nextgame.py
    – Defaults to today (start) and tomorrow (end), non-interactive.

  python3 nextgame.py -i
    – Interactive mode: prompts for start/end dates individually
      in mm/dd/YYYY format.

  python3 nextgame.py -d mm/dd/YYYY-mm/dd/YYYY
    – Direct date‐range mode: parse the single argument as
      start_date-end_date (both in mm/dd/YYYY). No further prompts.

Flags:
  -i, --interactive   Prompt for start and end dates separately.
  -d, --daterange     Provide date range directly as “mm/dd/YYYY-mm/dd/YYYY”.
"""

import statsapi
from datetime import datetime, timedelta
import pytz
import argparse
import sys

def prompt_date(prompt_text, default_date_str):
    """
    Prompt the user for a date in mm/dd/YYYY format.
    If the user hits Enter, return the default.
    """
    try:
        user_input = input(f"{prompt_text} [{default_date_str}]: ").strip()
    except EOFError:
        # If input() fails (e.g. piped), return default
        return default_date_str
    return user_input if user_input else default_date_str

def get_date_range(interactive=False, daterange_arg=None):
    """
    Return a tuple (start_date, end_date) in mm/dd/YYYY format.
    Modes:
      • interactive=True: prompt separately for start & end.
      • daterange_arg provided: parse as "mm/dd/YYYY-mm/dd/YYYY".
      • neither: default to today/tomorrow.
    """
    # compute defaults
    today_utc    = datetime.utcnow()
    tomorrow_utc = today_utc + timedelta(days=1)
    default_start = today_utc.strftime("%m/%d/%Y")
    default_end   = tomorrow_utc.strftime("%m/%d/%Y")

    if daterange_arg:
        parts = daterange_arg.split("-", 1)
        if len(parts) != 2:
            sys.exit("Error: date range must be MM/DD/YYYY-MM/DD/YYYY")
        start_date, end_date = parts[0], parts[1]
    elif interactive:
        start_date = prompt_date("Enter start date (mm/dd/YYYY)", default_start)
        end_date   = prompt_date("Enter end date   (mm/dd/YYYY)", default_end)
    else:
        start_date, end_date = default_start, default_end

    return start_date, end_date

def print_cubs_schedule(start_date, end_date):
    """
    Fetch and print the Chicago Cubs schedule between start_date and end_date.
    """
    games = statsapi.schedule(
        date=None,
        start_date=start_date,
        end_date=end_date,
        team="112",            # Cubs team ID
        opponent="",
        sportId=1,
        game_id=None,
        season=None,
        include_series_status=True
    )

    # time zone setup
    utc     = pytz.utc
    central = pytz.timezone("America/Chicago")

    for g in games:
        # parse & convert game_datetime
        game_dt_utc = utc.localize(datetime.strptime(
            g['game_datetime'], "%Y-%m-%dT%H:%M:%SZ"
        ))
        game_dt_chi = game_dt_utc.astimezone(central)

        # formatted fields
        date_str     = game_dt_chi.strftime("%b-%d-%a")   # e.g. Aug-01-Fri
        time_24      = game_dt_chi.strftime("%H:%M")      # 24-hour HH:MM
        venue        = g.get("venue_name", "Unknown Venue")
        away_name    = g.get("away_name", "Unknown Away")
        home_name    = g.get("home_name", "Unknown Home")
        status       = g.get("status", "Scheduled")
        away_pitcher = g.get("away_probable_pitcher") or "???"
        home_pitcher = g.get("home_probable_pitcher") or "???"

        # output
        print("---===Go Cubs!===---")
        print(f"{date_str} - {away_name} @ {home_name} ({status})")
        print(f"{time_24} Central @ {venue}")
        print(f"{away_pitcher} vs. {home_pitcher}")
        print("---===Go Cubs!===---\n")

def main():
    parser = argparse.ArgumentParser(
        description="Show Chicago Cubs games between two dates."
    )
    parser.add_argument(
        "-i", "--interactive",
        action="store_true",
        help="Prompt for start and end dates (mm/dd/YYYY) separately."
    )
    parser.add_argument(
        "-d", "--daterange",
        metavar="MM/DD/YYYY-MM/DD/YYYY",
        help="Provide start and end dates directly."
    )
    args = parser.parse_args()

    start_date, end_date = get_date_range(
        interactive=args.interactive,
        daterange_arg=args.daterange
    )
    print_cubs_schedule(start_date, end_date)

if __name__ == "__main__":
    main()