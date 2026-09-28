<?php
/**
 * Get a YouTube video transcript via the GetYouTubeTranscript REST API.
 * Standard library only (curl extension), no Composer dependencies.
 *
 * Usage:
 *   GYT_API_KEY=sk_live_... php get_transcript.php jNQXAC9IVRw
 *   GYT_API_KEY=sk_live_... php get_transcript.php "https://www.youtube.com/watch?v=jNQXAC9IVRw" en
 *
 * Docs: https://getyoutubetranscript.com/docs
 */

function base_url(): string
{
    $env = getenv('GYT_BASE_URL');
    return $env !== false ? $env : 'https://getyoutubetranscript.com/api/v1';
}

function get_transcript(string $apiKey, string $video, string $language = 'en'): array
{
    $url = base_url() . '/transcript?' . http_build_query([
        'v' => $video,
        'language' => $language,
    ]);

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => ["Authorization: Bearer {$apiKey}"],
        CURLOPT_TIMEOUT => 30,
    ]);

    $raw = curl_exec($ch);
    if ($raw === false) {
        $error = curl_error($ch);
        throw new RuntimeException("Network error: {$error}");
    }
    $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    // curl_close() is a deprecated no-op as of PHP 8.0+ (handles are freed
    // automatically once unreferenced) - intentionally omitted here.

    $body = json_decode($raw, true);
    if (!is_array($body)) {
        throw new RuntimeException("Could not parse response: {$raw}");
    }

    if ($status < 200 || $status >= 300 || empty($body['success'])) {
        $code = $body['code'] ?? 'UNKNOWN_ERROR';
        $message = $body['message'] ?? 'Request failed.';
        throw new RuntimeException("[{$status} {$code}] {$message}");
    }

    return $body['data'];
}

function main(array $argv): int
{
    if (count($argv) < 2) {
        fwrite(STDERR, "Usage: php get_transcript.php <video-url-or-id> [language]\n");
        return 1;
    }

    $apiKey = getenv('GYT_API_KEY');
    if ($apiKey === false || $apiKey === '') {
        fwrite(STDERR, "Set GYT_API_KEY first: export GYT_API_KEY=sk_live_...\n");
        return 1;
    }

    $video = $argv[1];
    $language = $argv[2] ?? 'en';

    try {
        $data = get_transcript($apiKey, $video, $language);
    } catch (RuntimeException $e) {
        fwrite(STDERR, 'Error: ' . $e->getMessage() . "\n");
        return 1;
    }

    echo "Title: {$data['title']}\n";
    echo "Author: {$data['author_name']}\n";
    echo "Words: {$data['word_count']}\n\n";
    echo $data['transcript'] . "\n";

    return 0;
}

exit(main($argv));
