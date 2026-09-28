#!/usr/bin/env python3
"""
List every video in a YouTube playlist, via the GetYouTubeTranscript
REST API. Fully paginated.

Usage:
    GYT_API_KEY=sk_live_... python playlist.py PLillGF-RfqbYE6Ik_EuXA2iZFcE082B3s
    GYT_API_KEY=sk_live_... python playlist.py PLillGF-RfqbYE6Ik_EuXA2iZFcE082B3s --max-pages 5

Docs: https://getyoutubetranscript.com/docs
"""
import argparse
import os
import sys

import requests

BASE_URL = os.environ.get("GYT_BASE_URL", "https://getyoutubetranscript.com/api/v1")


def get_playlist(api_key: str, list_id: str = None, continuation: str = None) -> dict:
    params = {"continuation": continuation} if continuation else {"list": list_id}
    response = requests.get(
        f"{BASE_URL}/playlist",
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
    parser.add_argument("playlist_id", help="Playlist ID or URL")
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
            data = get_playlist(
                api_key,
                list_id=args.playlist_id if page_num == 1 else None,
                continuation=continuation,
            )
        except RuntimeError as error:
            print(f"Error: {error}", file=sys.stderr)
            return 1

        if page_num == 1:
            print(f"Playlist: {data.get('title')}")

        videos = data.get("videos", [])
        total += len(videos)
        for video in videos:
            print(f"  #{video.get('position')}  {video.get('id')}  {video.get('title')}")

        if not data.get("has_more"):
            break
        continuation = data.get("continuation_token")
        if not continuation:
            break

    print(f"\nTotal videos fetched: {total}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
