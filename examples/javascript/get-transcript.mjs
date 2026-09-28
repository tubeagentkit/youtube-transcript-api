#!/usr/bin/env node
/**
 * Get a YouTube video transcript via the GetYouTubeTranscript REST API.
 * Uses native fetch (Node 18+), no dependencies.
 *
 * Usage:
 *   GYT_API_KEY=sk_live_... node get-transcript.mjs jNQXAC9IVRw
 *   GYT_API_KEY=sk_live_... node get-transcript.mjs "https://www.youtube.com/watch?v=jNQXAC9IVRw" en
 *
 * Docs: https://getyoutubetranscript.com/docs
 */

const BASE_URL = process.env.GYT_BASE_URL ?? "https://getyoutubetranscript.com/api/v1";

async function getTranscript(apiKey, video, language = "en") {
  const url = new URL(`${BASE_URL}/transcript`);
  url.searchParams.set("v", video);
  url.searchParams.set("language", language);

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
  const [video, language = "en"] = process.argv.slice(2);
  const apiKey = process.env.GYT_API_KEY;

  if (!apiKey) {
    console.error("Set GYT_API_KEY first: export GYT_API_KEY=sk_live_...");
    process.exit(1);
  }
  if (!video) {
    console.error("Usage: node get-transcript.mjs <video-url-or-id> [language]");
    process.exit(1);
  }

  try {
    const data = await getTranscript(apiKey, video, language);
    console.log(`Title: ${data.title}`);
    console.log(`Author: ${data.author_name}`);
    console.log(`Words: ${data.word_count}`);
    console.log();
    console.log(data.transcript);
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
}

main();
