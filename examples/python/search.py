#!/usr/bin/env python3
"""
Search YouTube videos or channels via the GetYouTubeTranscript REST API.

Usage:
    GYT_API_KEY=sk_live_... python search.py "lofi beats"
    GYT_API_KEY=sk_live_... python search.py mkbhd --type channel

Paginates automatically up to --max-pages using data.pagination.next_page_token.

Docs: https://getyoutubetranscript.com/docs
"""
import argparse
import os
import sys

import requests

BASE_URL = os.environ.get("GYT_BASE_URL", "https://getyoutubetranscript.com/api/v1")


def search(api_key: str, query: str = None, page_token: str = None, type_: str = None) -> dict:
    params = {}
    if page_token:
        params["page_token"] = page_token
    else:
        params["q"] = query
        if type_:
            params["type"] = type_

    response = requests.get(
        f"{BASE_URL}/search",
        headers={"Authorization": f"Bearer {api_key}"},
        params=params,
        timeout=30,
    )
    body = response.json()
    if not response.ok or not body.get("success"):
        code = body.get("code", "UNKNOWN_ERROR")
        message = body.get("message", "Request failed.")
        raise RuntimeError(f"[{response.status_code} {code}] {message}")
    return body["data"]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("query", help="Search query")
    parser.add_argument("--type", choices=["video", "channel"], default=None)
    parser.add_argument("--max-pages", type=int, default=1)
    args = parser.parse_args()

    api_key = os.environ.get("GYT_API_KEY")
    if not api_key:
        print("Set GYT_API_KEY first: export GYT_API_KEY=sk_live_...", file=sys.stderr)
        return 1

    page_token = None
    for page_num in range(1, args.max_pages + 1):
        try:
            data = search(api_key, query=args.query if page_num == 1 else None, page_token=page_token, type_=args.type)
        except RuntimeError as error:
            print(f"Error: {error}", file=sys.stderr)
            return 1

        results = data.get("video_results") or data.get("channel_results") or []
        print(f"--- page {page_num}: {len(results)} results ---")
        for item in results:
            title = item.get("title", "?")
            item_id = item.get("videoId") or item.get("channelId") or "?"
            print(f"  {item_id}  {title}")

        page_token = (data.get("pagination") or {}).get("next_page_token")
        if not page_token:
            break

    return 0


if __name__ == "__main__":
    sys.exit(main())
