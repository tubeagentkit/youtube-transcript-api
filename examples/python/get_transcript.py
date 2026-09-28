#!/usr/bin/env python3
"""
Get a YouTube video transcript via the GetYouTubeTranscript REST API.

Usage:
    GYT_API_KEY=sk_live_... python get_transcript.py jNQXAC9IVRw
    GYT_API_KEY=sk_live_... python get_transcript.py "https://www.youtube.com/watch?v=jNQXAC9IVRw" --language en

Docs: https://getyoutubetranscript.com/docs
"""
import argparse
import os
import sys

import requests

BASE_URL = os.environ.get("GYT_BASE_URL", "https://getyoutubetranscript.com/api/v1")


def get_transcript(api_key: str, video: str, language: str = "en") -> dict:
    response = requests.get(
        f"{BASE_URL}/transcript",
        headers={"Authorization": f"Bearer {api_key}"},
        params={"v": video, "language": language},
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
    parser.add_argument("video", help="YouTube video URL or 11-character video ID")
    parser.add_argument("--language", default="en", help="Caption language code (default: en)")
    args = parser.parse_args()

    api_key = os.environ.get("GYT_API_KEY")
    if not api_key:
        print("Set GYT_API_KEY first: export GYT_API_KEY=sk_live_...", file=sys.stderr)
        return 1

    try:
        data = get_transcript(api_key, args.video, args.language)
    except RuntimeError as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    print(f"Title: {data['title']}")
    print(f"Author: {data['author_name']}")
    print(f"Words: {data['word_count']}")
    print()
    print(data["transcript"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
