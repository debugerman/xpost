# xpost

A command-line tool and HTTP API for posting to X (Twitter).

## Installation

### macOS (Homebrew)

```bash
brew install owo-network/brew/xpost
```

### Linux / macOS (shell script)

```bash
curl -fsSL https://raw.githubusercontent.com/missuo/xpost/main/install.sh | bash
```

### Docker

```bash
docker pull ghcr.io/missuo/xpost:latest
```

### Build from source

```bash
go install github.com/missuo/xpost@latest
```

## Quick Start

### 1. Create an X Developer App

Go to [developer.x.com](https://developer.x.com) and create a new app. Enable **OAuth 2.0** under the authentication settings. Note your **Client ID**.

Add the following callback URL to your app:

```
http://localhost:9100
```

### 2. Log in

```bash
xpost login --client-id YOUR_CLIENT_ID
```

This opens your browser for authorization. After approving, the browser redirects to a URL starting with `http://localhost:9100?code=...`. Copy the full URL from your browser's address bar and paste it back into the terminal.

Tokens are saved to `~/.config/xpost/config.json` and refresh automatically.

### 3. Post a tweet

```bash
xpost tweet --text "Hello from xpost"
```

With media (up to 4 files, 8 MB each):

```bash
xpost tweet --text "Check this out" --media photo.jpg
xpost tweet --text "Two images" --media a.png --media b.png
```

## CLI Reference

```
xpost login     Authenticate via OAuth2
xpost tweet     Post a tweet
xpost serve     Start the HTTP API server
xpost install   Install as a systemd service (Linux)
xpost help      Show help
```

Running `xpost` with no arguments starts the HTTP server (same as `xpost serve`).

### `xpost login`

| Flag | Description |
|------|-------------|
| `--client-id` | OAuth2 Client ID (or `X_OAUTH2_CLIENT_ID` env) |
| `--client-secret` | OAuth2 Client Secret, if applicable |
| `--redirect-uri` | Callback URL (default `http://localhost:9100`) |
| `--scope` | Comma-separated scopes (default `tweet.read,tweet.write,users.read,offline.access`) |
| `--no-open` | Don't open the browser automatically |

All flags are optional after the first login. Values are read from the saved config.

### `xpost tweet`

| Flag | Description |
|------|-------------|
| `--text` | Tweet text |
| `--media` | Path to a media file (repeatable, max 4) |

### `xpost install`

Installs xpost as a systemd service. Requires `xpost login` to be run first.

```bash
sudo xpost install
```

| Flag | Description |
|------|-------------|
| `--bin` | Path to the xpost binary (default: current executable) |
| `--user` | systemd `User=` value (default: caller of sudo) |
| `--dry-run` | Print the unit file without installing |

After installation:

```bash
sudo systemctl status xpost
sudo systemctl restart xpost
sudo journalctl -u xpost -f
```

## HTTP API

Start the server with `xpost serve` or `sudo xpost install`. The API exposes a single endpoint:

### `POST /v1/tweets`

Requires an API token (auto-generated on first boot, stored in config):

```http
Authorization: Bearer <XPOST_API_TOKEN>
```

**JSON request:**

```bash
curl -X POST http://localhost:8080/v1/tweets \
  -H "Authorization: Bearer $XPOST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello from the API"}'
```

**JSON with base64 media:**

```bash
curl -X POST http://localhost:8080/v1/tweets \
  -H "Authorization: Bearer $XPOST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "With an image",
    "media_base64": ["'$(base64 < photo.jpg)'"],
    "media_content_types": ["image/jpeg"]
  }'
```

**Multipart form upload:**

```bash
curl -X POST http://localhost:8080/v1/tweets \
  -H "Authorization: Bearer $XPOST_API_TOKEN" \
  -F "text=Hello with upload" \
  -F "media=@photo.jpg"
```

## Docker Deployment

Docker runs the HTTP API server with OAuth1 credentials (no interactive login needed):

```bash
docker run -d --name xpost \
  -p 8080:8080 \
  -e XPOST_API_TOKEN="your-secret-token" \
  -e X_API_KEY="your-api-key" \
  -e X_API_SECRET="your-api-secret" \
  -e X_ACCESS_TOKEN="your-access-token" \
  -e X_ACCESS_TOKEN_SECRET="your-access-token-secret" \
  ghcr.io/missuo/xpost:latest
```

Or with Docker Compose — see [`compose.yaml`](compose.yaml).

## Vercel Deployment

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/missuo/xpost&project-name=xpost&repository-name=xpost)

Set these environment variables in the Vercel dashboard:

- `XPOST_API_TOKEN`
- `X_API_KEY`, `X_API_SECRET`, `X_ACCESS_TOKEN`, `X_ACCESS_TOKEN_SECRET`

## Configuration

Config is stored at `~/.config/xpost/config.json` by default. Override with `XPOST_CONFIG` env.

All settings can be overridden via environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `XPOST_CONFIG` | Config file path | `~/.config/xpost/config.json` |
| `XPOST_ADDR` | HTTP server listen address | `:8080` |
| `XPOST_API_TOKEN` | API token for HTTP endpoint | Auto-generated |
| `X_OAUTH2_CLIENT_ID` | OAuth2 Client ID | |
| `X_OAUTH2_CLIENT_SECRET` | OAuth2 Client Secret | |
| `X_OAUTH2_REDIRECT_URI` | OAuth2 Redirect URI | `http://localhost:9100` |
| `X_OAUTH2_SCOPE` | OAuth2 scopes (comma-separated) | `tweet.read,tweet.write,users.read,offline.access` |

OAuth1 credentials are also supported as an alternative authentication method:

| Variable | Description |
|----------|-------------|
| `X_API_KEY` | OAuth1 API Key |
| `X_API_SECRET` | OAuth1 API Secret |
| `X_ACCESS_TOKEN` | OAuth1 Access Token |
| `X_ACCESS_TOKEN_SECRET` | OAuth1 Access Token Secret |

## License

[Apache-2.0](LICENSE)
