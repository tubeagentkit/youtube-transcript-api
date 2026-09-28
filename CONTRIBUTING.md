# Contributing

This repo holds the public docs and example scripts for the GetYouTubeTranscript REST API. The API itself is closed-source and hosted; this repo is not where the server lives.

Useful contributions:

- A bug in one of the `examples/` scripts
- A docs correction (wrong parameter, outdated response shape, broken link)
- A new example in a language not covered yet

Before opening a PR:

1. Check the change against the live OpenAPI spec at https://getyoutubetranscript.com/openapi.json - that spec is the source of truth, not this repo's copy.
2. Keep examples dependency-light. Python examples should only need `requests`. JavaScript examples should use native `fetch`, no bundler. Go and PHP examples should use only the standard library.
3. Test your example against a real API key before submitting (`GYT_API_KEY=sk_live_... ./your-script`).

For anything about billing, account access, or the API itself (not this repo), use https://getyoutubetranscript.com/contact instead of opening an issue here.
