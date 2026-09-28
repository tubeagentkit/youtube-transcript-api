// Get a YouTube video transcript via the GetYouTubeTranscript REST API.
// Standard library only, no dependencies.
//
// Usage:
//
//	GYT_API_KEY=sk_live_... go run main.go jNQXAC9IVRw
//	GYT_API_KEY=sk_live_... go run main.go "https://www.youtube.com/watch?v=jNQXAC9IVRw" en
//
// Docs: https://getyoutubetranscript.com/docs
package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
)

const defaultBaseURL = "https://getyoutubetranscript.com/api/v1"

type transcriptData struct {
	VideoID      string `json:"video_id"`
	LanguageCode string `json:"language_code"`
	Title        string `json:"title"`
	AuthorName   string `json:"author_name"`
	Transcript   string `json:"transcript"`
	WordCount    int    `json:"word_count"`
}

type apiResponse struct {
	Success bool            `json:"success"`
	Data    transcriptData  `json:"data"`
	Code    string          `json:"code"`
	Message string          `json:"message"`
}

func baseURL() string {
	if v := os.Getenv("GYT_BASE_URL"); v != "" {
		return v
	}
	return defaultBaseURL
}

func getTranscript(apiKey, video, language string) (*transcriptData, error) {
	u, err := url.Parse(baseURL() + "/transcript")
	if err != nil {
		return nil, err
	}
	q := u.Query()
	q.Set("v", video)
	q.Set("language", language)
	u.RawQuery = q.Encode()

	req, err := http.NewRequest(http.MethodGet, u.String(), nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+apiKey)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var parsed apiResponse
	if err := json.Unmarshal(body, &parsed); err != nil {
		return nil, fmt.Errorf("could not parse response: %w", err)
	}

	if resp.StatusCode < 200 || resp.StatusCode >= 300 || !parsed.Success {
		return nil, fmt.Errorf("[%d %s] %s", resp.StatusCode, parsed.Code, parsed.Message)
	}

	return &parsed.Data, nil
}

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "Usage: go run main.go <video-url-or-id> [language]")
		os.Exit(1)
	}

	apiKey := os.Getenv("GYT_API_KEY")
	if apiKey == "" {
		fmt.Fprintln(os.Stderr, "Set GYT_API_KEY first: export GYT_API_KEY=sk_live_...")
		os.Exit(1)
	}

	video := os.Args[1]
	language := "en"
	if len(os.Args) > 2 {
		language = os.Args[2]
	}

	data, err := getTranscript(apiKey, video, language)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Title: %s\n", data.Title)
	fmt.Printf("Author: %s\n", data.AuthorName)
	fmt.Printf("Words: %d\n\n", data.WordCount)
	fmt.Println(data.Transcript)
}
