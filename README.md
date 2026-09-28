# YouTube Transcript API

[![License](https://img.shields.io/badge/License-MIT-4CAF50?style=for-the-badge)](./LICENSE)
[![Website](https://img.shields.io/badge/Website-getyoutubetranscript.com-FF3B00?style=for-the-badge)](https://getyoutubetranscript.com)
[![OpenAPI](https://img.shields.io/badge/OpenAPI-3.0.3-6BA539?style=for-the-badge&logo=openapiinitiative&logoColor=white)](./openapi.json)

A **YouTube Transcript API** built and hosted by [GetYouTubeTranscript](https://getyoutubetranscript.com): get YouTube video transcripts via REST API, no Google API key, no scraper to maintain, no yt-dlp or headless browser on your own servers. The same API also does YouTube search, channel metadata and full upload history, and playlist listing.

This repo is the public docs + examples home for the API: endpoint reference, the OpenAPI spec, and runnable examples in curl, Python, JavaScript, Go, and PHP. The API itself is a hosted service - there's no server code to run here.

## Why

Most "YouTube transcript" code you'll find is a scraper you run yourself: it works until YouTube changes something or your server's IP gets rate-limited, and then it's yours to fix. GetYouTubeTranscript runs that scraping infrastructure for you, behind one stable REST API:

- One API key, one bill, one thing to integrate against - not a scraper to patch every time YouTube changes its page structure
- Search, channel, and playlist endpoints alongside transcripts, so you're not stitching together three different tools
- A free tier (100 credits, no card) to try it before you commit to anything
- A published OpenAPI spec and official Python and Node.js SDKs

## Endpoints

All endpoints live under `https://getyoutubetranscript.com/api/v1`.

| Method | Path | Credits | Description |
| --- | --- | --- | --- |
| `GET` | `/transcript` | 1 | Full transcript for one video, plus title/author/thumbnail |
| `GET` | `/search` | 1 | Search YouTube videos or channels, paginated |
| `GET` | `/resolve` | free | Resolve a channel `@handle`/URL to a channel ID |
| `GET` | `/channel/latest` | free | Channel metadata + latest uploads (home-tab shelf) |
| `GET` | `/channel/search` | 1 | Search within one channel's videos, paginated |
| `GET` | `/channel/videos` | 1 | Full, paginated upload history for a channel |
| `GET` | `/playlist` | 1 | List every video in a playlist, paginated |
| `GET` | `/credits` | free | Check remaining credit balance, plan, and rate limit |
| `POST` | `/signup` | free | Self-serve signup step 1: email a 6-digit OTP |
| `POST` | `/signup/verify` | free | Self-serve signup step 2: verify OTP, mint an API key |

"Free" endpoints still require a valid API key and are still rate-limited - only the credit cost is zero.

## Authentication

Every request (except `/signup` and `/signup/verify`) needs an API key, sent as either:

```
Authorization: Bearer sk_live_...
```

or:

```
x-api-key: sk_live_...
```

Get a key at [getyoutubetranscript.com](https://getyoutubetranscript.com) (free tier, no card), or mint one in code with the self-serve signup flow - see [Examples](#examples).

## Quick start

```bash
curl "https://getyoutubetranscript.com/api/v1/transcript?v=jNQXAC9IVRw&language=en" \
  -H "Authorization: Bearer sk_live_..."
```

## Response example

```json
{
  "success": true,
  "data": {
    "video_id": "jNQXAC9IVRw",
    "language_code": "en",
    "title": "Me at the zoo",
    "author_name": "jawed",
    "author_url": "https://www.youtube.com/channel/UC4QobU6STFB0P71PVoOGeMg",
    "thumbnail_url": "https://i.ytimg.com/vi/jNQXAC9IVRw/hqdefault.jpg",
    "transcript": "All right, so here we are, in front of the elephants...",
    "word_count": 39
  }
}
```

`/transcript` returns one block of plain text, not per-segment timestamps.

## Parameters

### `GET /transcript`

| Param | Required | Description |
| --- | --- | --- |
| `v` | yes | YouTube video URL (full or short) or an 11-character video ID |
| `language` | no | Caption language code, e.g. `en`, `es` (default `en`) |

### `GET /search`

| Param | Required | Description |
| --- | --- | --- |
| `q` | yes, unless `page_token` is set | Search query, minimum 2 characters |
| `page_token` | no | Continuation token from a previous response's `data.pagination.next_page_token` |
| `type` | no | `video` (default) or `channel` - restricts to one kind, doesn't mix both |
| `country` | no | Two-letter region code, e.g. `us` |
| `language` | no | Result language hint, e.g. `en` |
| `limit` | no | Max results for this page |

### `GET /resolve`

| Param | Required | Description |
| --- | --- | --- |
| `handle` | yes | Channel `@handle`, channel URL, or `UC...` id |

### `GET /channel/latest`

| Param | Required | Description |
| --- | --- | --- |
| `channel` | yes | Channel `@handle`, URL, or `UC...` id |

### `GET /channel/search`

| Param | Required | Description |
| --- | --- | --- |
| `channel` | yes, unless `continuation` is set | Channel `@handle`, URL, or `UC...` id |
| `q` | yes, unless `continuation` is set | Query to search within the channel, minimum 2 characters |
| `continuation` | no | Continuation token from a previous response's `data.continuation_token` |

### `GET /channel/videos`

| Param | Required | Description |
| --- | --- | --- |
| `channel` | yes, unless `continuation` is set | Channel `@handle`, URL, or `UC...` id |
| `continuation` | no | Continuation token from a previous response's `data.continuation_token` |

### `GET /playlist`

| Param | Required | Description |
| --- | --- | --- |
| `list` | yes, unless `continuation` is set | Playlist ID or URL |
| `continuation` | no | Continuation token from a previous response's `data.continuation_token` |

All continuation/page tokens are opaque - pass them back exactly as received, don't inspect or construct them.

## Errors

Every error response has this shape:

```json
{ "success": false, "code": "INVALID_API_KEY", "message": "This API key is invalid or has been revoked." }
```

| HTTP status | Code | Meaning |
| --- | --- | --- |
| 400 | `BAD_REQUEST` / endpoint-specific codes (e.g. `MISSING_URL`, `INVALID_URL`) | Missing or invalid parameters |
| 401 | `MISSING_API_KEY` | No key provided in `Authorization: Bearer` or `x-api-key` |
| 401 | `INVALID_API_KEY` | Key is invalid or has been revoked |
| 402 | `PAYMENT_REQUIRED` | Out of credits - response includes `creditsLeft` and `topupCreditsLeft` |
| 404 | endpoint-specific (e.g. video/channel/playlist not found, no captions available) | Resource doesn't exist or has no transcript |
| 429 | `RATE_LIMITED` | Rate limit exceeded for your plan tier - response includes `requestsThisMinute` |
| 500 | `INTERNAL_ERROR` | Something broke on our end |

Failed and rate-limited requests are never charged a credit - only a successful (2xx) response consumes one.

## Rate limits

Rate limits are per API key, per plan tier:

| Plan | Requests/minute |
| --- | --- |
| Free | 60 |
| Monthly ($5/mo) | 200 |
| Annual ($4.50/mo) | 300 |

A `429` response includes `requestsThisMinute` so you can back off accordingly.

## Pagination

`search`, `playlist`, `channel/search`, and `channel/videos` are all paginated the same way: the first response includes a continuation token (`data.pagination.next_page_token` for `/search`, `data.continuation_token` for the others). Pass that token back on the next call and drop the original query params. A missing/`null` token, or `has_more: false`, means there are no more pages.

## Examples

More complete, runnable versions of these live in [`examples/`](./examples), reading the API key from the `GYT_API_KEY` environment variable.

### curl

```bash
curl "https://getyoutubetranscript.com/api/v1/transcript?v=jNQXAC9IVRw" \
  -H "Authorization: Bearer $GYT_API_KEY"
```

### Python

```python
import requests

response = requests.get(
    "https://getyoutubetranscript.com/api/v1/transcript",
    headers={"Authorization": f"Bearer {api_key}"},
    params={"v": "jNQXAC9IVRw"},
)
data = response.json()["data"]
print(data["title"], data["transcript"])
```

### JavaScript

```javascript
const response = await fetch(
  `https://getyoutubetranscript.com/api/v1/transcript?v=jNQXAC9IVRw`,
  { headers: { Authorization: `Bearer ${apiKey}` } }
);
const { data } = await response.json();
console.log(data.title, data.transcript);
```

Run any example: `GYT_API_KEY=sk_live_... python examples/python/get_transcript.py jNQXAC9IVRw`

## Official SDKs

- [youtube-transcript-api-python](https://github.com/tubeagentkit/youtube-transcript-api-python) - typed Python client, plus self-serve signup helpers
- [youtube-transcript-api-node](https://github.com/tubeagentkit/youtube-transcript-api-node) - zero-dependency Node.js/TypeScript client, ESM + CJS

## Other integrations

- [youtube-mcp](https://github.com/tubeagentkit/youtube-mcp) - remote MCP server so Claude, ChatGPT, Cursor, and VS Code can call this API as a tool
- [youtube-transcript-skills](https://github.com/tubeagentkit/youtube-transcript-skills) - Agent Skill for Claude Code, Cursor, and other coding agents
- [n8n-nodes-getyoutubetranscript](https://www.npmjs.com/package/n8n-nodes-getyoutubetranscript) - n8n community node for workflow automation
- [Chrome extension](https://getyoutubetranscript.com) - get a transcript and ask AI questions about any video without leaving YouTube

## Use cases

- **AI pipelines** - feed transcripts into an LLM for summarization, RAG, or chat over video content
- **Content repurposing** - turn a video into a blog post, newsletter, or social copy
- **Research** - pull transcripts across many videos for analysis at scale
- **Channel monitoring** - poll `/channel/videos` or `/channel/latest` to catch new uploads from channels you track
- **YouTube search in your app** - `/search` without needing a Google Cloud project or API key

## Compared with youtube-transcript-api (Python library)

[jdepoix/youtube-transcript-api](https://github.com/jdepoix/youtube-transcript-api) is a well-known open-source Python library for pulling YouTube captions. It's free, it's good, and for local scripts and small personal projects it's often the right tool.

Where it and this API differ:

| | This API | jdepoix/youtube-transcript-api |
| --- | --- | --- |
| Runs where | Our servers (hosted) | Your machine / your server, from your own IP |
| Cloud hosting | Not affected - we handle the scraping infra | Frequently blocked by YouTube on AWS/GCP/Azure IP ranges |
| Language | Any HTTP client | Python only |
| Search | Yes (`/search`) | No |
| Channel data | Yes (`/channel/*`, `/resolve`) | No |
| Playlist listing | Yes (`/playlist`) | No |
| Cost | Free tier, then metered credits | Free, always |
| Maintenance | We maintain it | You update the package when YouTube changes something |

If you're running a quick local script and don't want to sign up for anything, jdepoix's library is genuinely a good choice. If you're running on a server (especially a cloud provider IP that YouTube is more likely to rate-limit), want search/channel/playlist data too, or don't want to be the one who fixes the scraper when it breaks, that's what this API is for.

## FAQ

**Is there an official YouTube transcript API?**
Not for arbitrary videos. The official YouTube Data API has a `captions.download` method, but it only works for videos you own and requires OAuth as the channel owner. GetYouTubeTranscript is an independent hosted API (not affiliated with YouTube or Google) that returns the transcript of any public video with captions, along with search, channel, and playlist data.

**Do I need a Google API key?**
No. You only need a GetYouTubeTranscript API key, obtained from the dashboard or the self-serve `/signup` + `/signup/verify` flow. No Google Cloud project, no OAuth.

**Does it work for videos without captions?**
`/transcript` returns whatever captions are available for the video (creator-provided or YouTube auto-captions), in the language you request via `language`. If a video has no captions at all, disabled captions, or no captions in the requested language, the endpoint returns a 404 - there's no audio-transcription fallback.

**How much does it cost?**
Free: 100 credits, no card required. Monthly: $5 for 1,000 credits/month, top-ups at $2.50/1,000. Annual: $4.50/mo (billed $54/year) for 1,000 credits/month, top-ups at $1.50/1,000 (40% cheaper). 1 credit = 1 successful request; failed and rate-limited requests aren't charged. Several endpoints (`/resolve`, `/channel/latest`, `/credits`) are always free.

**What are the rate limits?**
60 requests/minute on the free tier, 200/min on Monthly, 300/min on Annual - see [Rate limits](#rate-limits).

## Links

- [Docs](https://getyoutubetranscript.com/docs)
- [OpenAPI spec (live)](https://getyoutubetranscript.com/openapi.json) - the copy in this repo ([`openapi.json`](./openapi.json)) is a snapshot; the live URL is canonical
- [Pricing](https://getyoutubetranscript.com)
- [GetYouTubeTranscript on GitHub](https://github.com/tubeagentkit)

## Related projects

- [youtube-transcript-api-python](https://github.com/tubeagentkit/youtube-transcript-api-python)
- [youtube-transcript-api-node](https://github.com/tubeagentkit/youtube-transcript-api-node)
- [youtube-mcp](https://github.com/tubeagentkit/youtube-mcp)
- [youtube-transcript-skills](https://github.com/tubeagentkit/youtube-transcript-skills)
- [n8n-nodes-getyoutubetranscript](https://www.npmjs.com/package/n8n-nodes-getyoutubetranscript)

## License

MIT - see [LICENSE](./LICENSE). The GetYouTubeTranscript API itself is a proprietary hosted service; this repo's docs and example code are MIT.
