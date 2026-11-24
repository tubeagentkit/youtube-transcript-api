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
# Poll an AI transcript job (job_id from a 202 answer of transcript_ai):
#   ./examples.sh transcript_job <job_id>

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

transcript_ai() {
  # AI speech-to-text transcript: 3 credits per minute of video (min 3).
  # mode=auto uses captions when the video has them (1 credit).
  # A 200 has the transcript; a 202 has a job to poll with transcript_job.
  echo "=== GET /transcript (mode=generate) ==="
  curl -sS -D - "${auth_header[@]}" \
    "${BASE_URL}/transcript?v=jNQXAC9IVRw&mode=generate" | grep -i -E '^(HTTP|x-credits-charged)|^\{' || true
  echo
}

transcript_job() {
  local job_id="${1:-${GYT_JOB_ID:-}}"
  if [ -z "$job_id" ]; then
    echo "=== GET /transcript/jobs ==="
    echo "Pass a job_id from a 202 answer: ./examples.sh transcript_job <job_id> (or set GYT_JOB_ID). Skipped."
    echo
    return
  fi
  # Free. 202 while queued or running, 200 when done, an error if it failed.
  local code
  for _ in $(seq 1 60); do
    code=$(curl -sS -o /tmp/gyt-job.json -w '%{http_code}' "${auth_header[@]}" \
      "${BASE_URL}/transcript/jobs?id=${job_id}")
    [ "$code" = "202" ] || break
    sleep 5
  done
  echo "=== GET /transcript/jobs (HTTP ${code}) ==="
  python3 -m json.tool /tmp/gyt-job.json 2>/dev/null || cat /tmp/gyt-job.json
  echo
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

channel_shorts() {
  run "GET /channel/videos (Shorts, most popular first)" "${auth_header[@]}" \
    -G --data-urlencode "channel=@mkbhd" --data-urlencode "tab=shorts" --data-urlencode "sort=popular" \
    "${BASE_URL}/channel/videos"
}

channel_playlists() {
  run "GET /channel/playlists" "${auth_header[@]}" \
    -G --data-urlencode "channel=@mkbhd" \
    "${BASE_URL}/channel/playlists"
}

channel_posts() {
  run "GET /channel/posts" "${auth_header[@]}" \
    -G --data-urlencode "channel=@mkbhd" \
    "${BASE_URL}/channel/posts"
}

channel_banner() {
  run "GET /channel/banner" "${auth_header[@]}" \
    -G --data-urlencode "channel=@mkbhd" \
    "${BASE_URL}/channel/banner"
}

video_related() {
  run "GET /video/related" "${auth_header[@]}" \
    -G --data-urlencode "v=dQw4w9WgXcQ" \
    "${BASE_URL}/video/related"
}

video_dislikes() {
  run "GET /video/dislikes" "${auth_header[@]}" \
    -G --data-urlencode "v=dQw4w9WgXcQ" \
    "${BASE_URL}/video/dislikes"
}

video_details() {
  run "GET /video" "${auth_header[@]}" \
    -G --data-urlencode "v=dQw4w9WgXcQ" \
    "${BASE_URL}/video"
}

video_comments() {
  run "GET /video/comments" "${auth_header[@]}" \
    -G --data-urlencode "v=dQw4w9WgXcQ" \
    "${BASE_URL}/video/comments"
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
  transcript_ai) transcript_ai ;;
  transcript_job) transcript_job "${2:-}" ;;
  search) search_videos ;;
  search_channels) search_channels ;;
  resolve) resolve_channel ;;
  channel_latest) channel_latest ;;
  channel_videos) channel_videos ;;
  channel_search) channel_search ;;
  channel_shorts) channel_shorts ;;
  channel_playlists) channel_playlists ;;
  channel_posts) channel_posts ;;
  channel_banner) channel_banner ;;
  video_related) video_related ;;
  video_dislikes) video_dislikes ;;
  video_details) video_details ;;
  video_comments) video_comments ;;
  playlist) playlist ;;
  credits) credits ;;
  signup) signup_flow ;;
  all)
    transcript
    transcript_timestamps
    transcript_ai
    transcript_job
    search_videos
    search_channels
    resolve_channel
    channel_latest
    channel_videos
    channel_search
    channel_shorts
    channel_playlists
    channel_posts
    channel_banner
    video_related
    video_dislikes
    video_details
    video_comments
    playlist
    credits
    signup_flow
    ;;
  *)
    echo "Unknown example: $1" >&2
    exit 1
    ;;
esac
