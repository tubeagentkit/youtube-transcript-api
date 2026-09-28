#!/usr/bin/env node
/**
 * Search YouTube videos or channels via the GetYouTubeTranscript REST API.
 * Uses native fetch (Node 18+), no dependencies.
 *
 * Usage:
 *   GYT_API_KEY=sk_live_... node search.mjs "lofi beats"
 *   GYT_API_KEY=sk_live_... node search.mjs mkbhd channel
 *
 * Docs: https://getyoutubetranscript.com/docs
 */

const BASE_URL = process.env.GYT_BASE_URL ?? "https://getyoutubetranscript.com/api/v1";

async function search(apiKey, { query, pageToken, type } = {}) {
  const url = new URL(`${BASE_URL}/search`);
  if (pageToken) {
    url.searchParams.set("page_token", pageToken);
  } else {
    url.searchParams.set("q", query);
    if (type) url.searchParams.set("type", type);
  }

  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${apiKey}` },
  });
  const body = await response.json();

  if (!response.ok || !body.success) {
    throw new Error(`[${response.status} ${body.code ?? "UNKNOWN_ERROR"}] ${body.message ?? "Request failed."}`);
  }
  return body.data;
}

async function main() {
  const [query, type] = process.argv.slice(2);
  const apiKey = process.env.GYT_API_KEY;

  if (!apiKey) {
    console.error("Set GYT_API_KEY first: export GYT_API_KEY=sk_live_...");
    process.exit(1);
  }
  if (!query) {
    console.error("Usage: node search.mjs <query> [video|channel]");
    process.exit(1);
  }

  try {
    const data = await search(apiKey, { query, type });
    const results = data.video_results ?? data.channel_results ?? [];
    console.log(`${results.length} results`);
    for (const item of results) {
      const id = item.videoId ?? item.channelId ?? "?";
      console.log(`  ${id}  ${item.title}`);
    }
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
}

main();
