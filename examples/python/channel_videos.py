#!/usr/bin/env python3
"""
List every video a YouTube channel has uploaded, via the
GetYouTubeTranscript REST API. Walks the full paginated /videos tab
(not just the home-tab "latest" shelf).

Usage:
    GYT_API_KEY=sk_live_... python channel_videos.py @mkbhd
    GYT_API_KEY=sk_live_... python channel_videos.py @mkbhd --max-pages 3

Docs: https://getyoutubetranscript.com/docs
"""
import argparse
import os
import sys

import requests

BASE_URL = os.environ.get("GYT_BASE_URL", "https://getyoutubetranscript.com/api/v1")


def channel_videos(api_key: str, channel: str = None, continuation: str = None) -> dict:
    params = {"continuation": continuation} if continuation else {"channel": channel}
    response = requests.get(
        f"{BASE_URL}/channel/videos",
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
    parser.add_argument("channel", help="Channel @handle, URL, or UC... id")
    parser.add_argument("--max-pages", type=int, default=1)
    args = parser.parse_args()

    api_key = os.environ.get("GYT_API_KEY")
    if not api_key:
        print("Set GYT_API_KEY first: export GYT_API_KEY=sk_live_...", file=sys.stderr)
        return 1

    continuation = None
    total = 0
    for page_num in range(1, args.max_pages + 1):
        try:
            data = channel_videos(
                api_key,
                channel=args.channel if page_num == 1 else None,
                continuation=continuation,
            )
        except RuntimeError as error:
            print(f"Error: {error}", file=sys.stderr)
            return 1

        videos = data.get("videos", [])
        total += len(videos)
        print(f"--- page {page_num}: {len(videos)} videos ---")
        for video in videos:
            print(f"  {video.get('id')}  {video.get('title')}  ({video.get('length')})")

        if not data.get("has_more"):
            break
        continuation = data.get("continuation_token")
        if not continuation:
            break

    print(f"\nTotal videos fetched: {total}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
