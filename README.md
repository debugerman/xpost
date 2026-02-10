# xpost

A Gin-based API server for posting to X (Twitter) via `xdk-go`, with strict API-token protection and media support.

## Highlights

- Supports text tweets and image tweets.
- Supports `Authorization: Bearer <token>` and `X-API-Token: <token>`.
- First run requires X credentials from environment variables.
- Optional local config persistence (`config.json`) for non-serverless mode.
- Includes Vercel entrypoint, Dockerfile, Compose, and Docker build CI workflow.

## Project Layout

- `main.go`: local runtime entrypoint.
- `internal/app/app.go`: core server/router logic.
- `api/entrypoint.go`: Vercel serverless entrypoint.
- `vercel.json`: Vercel rewrites and CORS header.
- `Dockerfile`: production container image.
- `compose.yaml`: local container orchestration.
- `.github/workflows/docker-release.yml`: GitHub Actions Docker release workflow.
- `.github/workflows/release.yml`: GitHub Actions binary release workflow.

## Auth Model

There are two different auth layers:

1. **xpost API protection** (your own server protection)
- Header `Authorization: Bearer <XPOST_API_TOKEN>` or `X-API-Token: <XPOST_API_TOKEN>`.

2. **X platform auth** (credentials used to post on X)
- OAuth1:
  - `X_API_KEY`
  - `X_API_SECRET`
  - `X_ACCESS_TOKEN`
  - `X_ACCESS_TOKEN_SECRET`
- Or OAuth2 user token:
  - `X_OAUTH2_ACCESS_TOKEN`

## Environment Variables

- `XPOST_ADDR`: listen address, default `:8080`.
- `XPOST_CONFIG`: config path (local mode), default `config.json`.
- `XPOST_API_TOKEN`: API token for protecting endpoints.
- `X_API_KEY`: OAuth1 API key.
- `X_API_SECRET`: OAuth1 API secret.
- `X_ACCESS_TOKEN`: OAuth1 access token.
- `X_ACCESS_TOKEN_SECRET`: OAuth1 access token secret.
- `X_OAUTH2_ACCESS_TOKEN`: OAuth2 user access token.

## Local Run

### 1. Set credentials

OAuth1 example:

```bash
export X_API_KEY="..."
export X_API_SECRET="..."
export X_ACCESS_TOKEN="..."
export X_ACCESS_TOKEN_SECRET="..."
```

Optional API token:

```bash
export XPOST_API_TOKEN="your-strong-token"
```

### 2. Start service

```bash
go run .
```

Default address is `http://localhost:8080`.

### 3. First-run behavior

- If `XPOST_API_TOKEN` is not set in local mode, token is auto-generated and stored in `config.json`.
- If X credentials are missing on first run, startup fails.

## Docker

Build:

```bash
docker build -t xpost:latest .
```

Run:

```bash
docker run --rm -p 8080:8080 \
  -e XPOST_API_TOKEN="your-strong-token" \
  -e X_API_KEY="..." \
  -e X_API_SECRET="..." \
  -e X_ACCESS_TOKEN="..." \
  -e X_ACCESS_TOKEN_SECRET="..." \
  -e XPOST_CONFIG="/data/config.json" \
  -v xpost_data:/data \
  xpost:latest
```

## Docker Compose

1. Edit credential values directly in `compose.yaml` under `services.xpost.environment`.
2. Start:

```bash
docker compose up --build
```

Compose exposes `http://localhost:8080` and persists config to volume `xpost_data`.
Do not commit real secrets if you replace placeholders in `compose.yaml`.

## Vercel Deployment

Included files:

- `api/entrypoint.go`
- `vercel.json`
- `.vercelignore`

Required Vercel environment variables:

- `XPOST_API_TOKEN`
- Either OAuth1 set:
  - `X_API_KEY`
  - `X_API_SECRET`
  - `X_ACCESS_TOKEN`
  - `X_ACCESS_TOKEN_SECRET`
- Or OAuth2:
  - `X_OAUTH2_ACCESS_TOKEN`

Note:
- Vercel mode is stateless. Admin config updates apply to the warm instance only; use Vercel environment variables as source of truth.

## API Reference

Base URL examples:

- Local: `http://localhost:8080`
- Vercel: `https://<your-domain>`

Protected endpoints require one of:

```http
Authorization: Bearer <XPOST_API_TOKEN>
```

or

```http
X-API-Token: <XPOST_API_TOKEN>
```

### `GET /healthz`

Auth: not required.

Response:

```json
{
  "status": "ok"
}
```

### `GET /v1/admin/config`

Auth: required.

Purpose:
- Returns non-secret status for current runtime config.

Response example:

```json
{
  "server": { "addr": ":8080" },
  "auth_mode": "oauth1",
  "x_ready": true,
  "x_last_err": "",
  "x": {
    "api_key_set": true,
    "api_secret_set": true,
    "access_token_set": true,
    "access_token_secret_set": true,
    "oauth2_access_token_set": false
  }
}
```

### `PUT /v1/admin/auth`

Auth: required.

Purpose:
- Updates X auth in current runtime.
- In local mode, persists to `XPOST_CONFIG`.
- In serverless/stateless mode, does not persist across cold starts.

Request body (send any non-empty subset):

```json
{
  "api_key": "...",
  "api_secret": "...",
  "access_token": "...",
  "access_token_secret": "...",
  "oauth2_access_token": "..."
}
```

Response example:

```json
{
  "ok": true,
  "x_ready": true,
  "auth_mode": "oauth1",
  "x_last_err": ""
}
```

### `POST /v1/admin/api-token/rotate`

Auth: required.

Purpose:
- Rotates API protection token.

Request body:

- Empty body: auto-generate.
- Or explicit token:

```json
{
  "api_token": "your-new-token"
}
```

Response:

```json
{
  "ok": true,
  "api_token": "your-new-token-or-generated-token"
}
```

### `POST /v1/tweets`

Auth: required.

Purpose:
- Create a tweet with optional images.

Supported content types:

1. `application/json` for text-only or base64 media.
2. `multipart/form-data` for file upload.

#### JSON: text only

```bash
curl -X POST http://localhost:8080/v1/tweets \
  -H "Authorization: Bearer <XPOST_API_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello from xpost"}'
```

#### JSON: base64 media

```bash
curl -X POST http://localhost:8080/v1/tweets \
  -H "Authorization: Bearer <XPOST_API_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "text":"Hello with image",
    "media_base64":["<base64-encoded-image>"],
    "media_content_types":["image/jpeg"]
  }'
```

JSON fields:

- `text`: optional when media is present.
- `media_base64`: optional list, max 4.
- `media_content_types`: optional list, if provided must match `media_base64` length.

#### Multipart: file upload

```bash
curl -X POST http://localhost:8080/v1/tweets \
  -H "X-API-Token: <XPOST_API_TOKEN>" \
  -F "text=Hello with upload" \
  -F "media=@/absolute/path/image1.jpg" \
  -F "media=@/absolute/path/image2.png"
```

Multipart fields:

- `text`: optional when media is present.
- `media`: repeatable file field, max 4 files.

Response example:

```json
{
  "ok": true,
  "auth_mode": "oauth1",
  "media": [
    {
      "id": "2021093636398776322"
    }
  ],
  "media_count": 1,
  "tweet": {
    "data": {
      "id": "2021093638541807805",
      "text": "Hello with upload https://t.co/xxxx"
    }
  }
}
```

## Limits

- Max media count per request: `4`
- Max media size per item: `8 MB`
- Tweet request timeout: `90s`

## Common Errors

- `401 {"error":"invalid api token"}`: missing/invalid API token header.
- `503 {"error":"api token is not configured"}`: server protection token missing.
- `503 {"error":"x client is not ready"}` or similar: X auth runtime is not ready.
- `400 {"error":"text or media is required"}`: empty tweet payload.
- `400 {"error":"too many media files, max is 4"}`: media count exceeded.
- `502 {"error":"...x api error..."}`: upstream X API request failed.

## CI

GitHub Actions workflows:

- `.github/workflows/release.yml`
  - Trigger: GitHub Release `published` (tag-based release).
  - Action: run `go test ./...`, build multi-platform binaries, upload artifacts + checksums to Release.
- `.github/workflows/docker-release.yml`
  - Trigger: GitHub Release `published` (tag-based release).
  - Action: build and push multi-arch Docker images to GHCR with tags:
    - `<release-tag>`
    - `latest`

## Security Notes

- Never commit real credentials or `.env`.
- `.gitignore`, `.dockerignore`, and `.vercelignore` already exclude common secret files.
- Prefer rotating `XPOST_API_TOKEN` regularly via `POST /v1/admin/api-token/rotate`.
