#!/usr/bin/env bash
# GetYouTubeTranscript API - curl examples
#
# Set GYT_API_KEY first:
#   export GYT_API_KEY=sk_live_...
#
# Run all examples:
#   ./examples.sh
# Run one:
#   ./examples.sh transcript

set -euo pipefail

BASE_URL="${GYT_BASE_URL:-https://getyoutubetranscript.com/api/v1}"

if [ -z "${GYT_API_KEY:-}" ]; then
  echo "Set GYT_API_KEY first: export GYT_API_KEY=sk_live_..." >&2
  exit 1
fi

auth_header=(-H "Authorization: Bearer ${GYT_API_KEY}")

run() {
  echo "=== $1 ==="
  shift
  curl -sS "$@" | python3 -m json.tool 2>/dev/null || true
  echo
}

transcript() {
  run "GET /transcript" "${auth_header[@]}" \
    "${BASE_URL}/transcript?v=jNQXAC9IVRw&language=en"
}

transcript_timestamps() {
  run "GET /transcript (with segments)" "${auth_header[@]}" \
    "${BASE_URL}/transcript?v=jNQXAC9IVRw&language=en&timestamps=true"
}

search_videos() {
  run "GET /search (videos)" "${auth_header[@]}" \
    -G --data-urlencode "q=lofi beats" \
    "${BASE_URL}/search"
}

search_channels() {
  run "GET /search (channels)" "${auth_header[@]}" \
    -G --data-urlencode "q=mkbhd" --data-urlencode "type=channel" \
    "${BASE_URL}/search"
}

resolve_channel() {
  run "GET /resolve" "${auth_header[@]}" \
    -G --data-urlencode "handle=@mkbhd" \
    "${BASE_URL}/resolve"
}

channel_latest() {
  run "GET /channel/latest" "${auth_header[@]}" \
    -G --data-urlencode "channel=@mkbhd" \
    "${BASE_URL}/channel/latest"
}

channel_videos() {
  run "GET /channel/videos" "${auth_header[@]}" \
    -G --data-urlencode "channel=@mkbhd" \
    "${BASE_URL}/channel/videos"
}

channel_search() {
  run "GET /channel/search" "${auth_header[@]}" \
    -G --data-urlencode "channel=@mkbhd" --data-urlencode "q=iphone" \
    "${BASE_URL}/channel/search"
}

playlist() {
  run "GET /playlist" "${auth_header[@]}" \
    -G --data-urlencode "list=PLillGF-RfqbYE6Ik_EuXA2iZFcE082B3s" \
    "${BASE_URL}/playlist"
}

credits() {
  run "GET /credits" "${auth_header[@]}" \
    "${BASE_URL}/credits"
}

signup_flow() {
  echo "=== POST /signup + /signup/verify (no API key needed) ==="
  echo "This sends a real 6-digit code to the given email. Skipped in this batch run."
  echo 'curl -X POST '"${BASE_URL}"'/signup -H "Content-Type: application/json" -d '"'"'{"email":"you@example.com"}'"'"''
  echo 'curl -X POST '"${BASE_URL}"'/signup/verify -H "Content-Type: application/json" -d '"'"'{"email":"you@example.com","otp":"123456"}'"'"''
  echo
}

case "${1:-all}" in
  transcript) transcript ;;
  transcript_timestamps) transcript_timestamps ;;
  search) search_videos ;;
  search_channels) search_channels ;;
  resolve) resolve_channel ;;
  channel_latest) channel_latest ;;
  channel_videos) channel_videos ;;
  channel_search) channel_search ;;
  playlist) playlist ;;
  credits) credits ;;
  signup) signup_flow ;;
  all)
    transcript
    transcript_timestamps
    search_videos
    search_channels
    resolve_channel
    channel_latest
    channel_videos
    channel_search
    playlist
    credits
    signup_flow
    ;;
  *)
    echo "Unknown example: $1" >&2
    exit 1
    ;;
esac
