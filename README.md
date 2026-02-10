# xpost

Post to X (Twitter) through a protected HTTP API.

## Quick Deploy (Recommended: Docker Compose + GHCR)

`compose.yaml` already pulls the image from GHCR (`ghcr.io/missuo/xpost:latest`).

1. Edit credentials in `compose.yaml` -> `services.xpost.environment`
2. Start:

```bash
docker compose pull
docker compose up -d
```

3. Check health:

```bash
curl http://localhost:8080/healthz
```

## Quick Deploy (docker run)

```bash
docker run -d --name xpost \
  -p 8080:8080 \
  -e XPOST_ADDR=":8080" \
  -e XPOST_CONFIG="/data/config.json" \
  -e XPOST_API_TOKEN="replace-with-strong-token" \
  -e X_API_KEY="replace-with-x-api-key" \
  -e X_API_SECRET="replace-with-x-api-secret" \
  -e X_ACCESS_TOKEN="replace-with-x-access-token" \
  -e X_ACCESS_TOKEN_SECRET="replace-with-x-access-token-secret" \
  -v xpost_data:/data \
  ghcr.io/missuo/xpost:latest
```

## Vercel Deploy

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/missuo/xpost&project-name=xpost&repository-name=xpost&env=XPOST_API_TOKEN,X_API_KEY,X_API_SECRET,X_ACCESS_TOKEN,X_ACCESS_TOKEN_SECRET,X_OAUTH2_ACCESS_TOKEN)

After import, set environment variables in Vercel:

- `XPOST_API_TOKEN` (required)
- OAuth1 (recommended):
  - `X_API_KEY`
  - `X_API_SECRET`
  - `X_ACCESS_TOKEN`
  - `X_ACCESS_TOKEN_SECRET`
- Or OAuth2:
  - `X_OAUTH2_ACCESS_TOKEN`

Then deploy and call your production domain directly.

## Required Environment Variables

### API Protection (required)

- `XPOST_API_TOKEN`

### X Credentials (choose one mode)

OAuth1 (recommended):

- `X_API_KEY`
- `X_API_SECRET`
- `X_ACCESS_TOKEN`
- `X_ACCESS_TOKEN_SECRET`

OAuth2 alternative:

- `X_OAUTH2_ACCESS_TOKEN`

### Optional

- `XPOST_ADDR` (default `:8080`)
- `XPOST_CONFIG` (default `config.json`)

## How to Call the API

Protected endpoints require one header:

```http
Authorization: Bearer <XPOST_API_TOKEN>
```

or

```http
X-API-Token: <XPOST_API_TOKEN>
```

## API Reference

### `GET /healthz`

No auth required.

Response:

```json
{
  "status": "ok"
}
```

### `GET /v1/admin/config` (protected)

Returns runtime status (without exposing secrets).

Example:

```bash
curl -H "Authorization: Bearer <XPOST_API_TOKEN>" \
  http://localhost:8080/v1/admin/config
```

### `PUT /v1/admin/auth` (protected)

Updates X auth at runtime.

Request body (non-empty subset):

```json
{
  "api_key": "...",
  "api_secret": "...",
  "access_token": "...",
  "access_token_secret": "...",
  "oauth2_access_token": "..."
}
```

Example:

```bash
curl -X PUT http://localhost:8080/v1/admin/auth \
  -H "Authorization: Bearer <XPOST_API_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "api_key":"...",
    "api_secret":"...",
    "access_token":"...",
    "access_token_secret":"..."
  }'
```

### `POST /v1/admin/api-token/rotate` (protected)

Rotate API protection token.

Auto-generate:

```bash
curl -X POST http://localhost:8080/v1/admin/api-token/rotate \
  -H "Authorization: Bearer <XPOST_API_TOKEN>"
```

Specify token:

```bash
curl -X POST http://localhost:8080/v1/admin/api-token/rotate \
  -H "Authorization: Bearer <XPOST_API_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"api_token":"your-new-token"}'
```

### `POST /v1/tweets` (protected)

Create text tweets or tweets with media.

#### 1) JSON text-only

```bash
curl -X POST http://localhost:8080/v1/tweets \
  -H "Authorization: Bearer <XPOST_API_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello from xpost"}'
```

#### 2) JSON with base64 media

```bash
curl -X POST http://localhost:8080/v1/tweets \
  -H "Authorization: Bearer <XPOST_API_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "text":"Hello with image",
    "media_base64":["<base64-image>"],
    "media_content_types":["image/jpeg"]
  }'
```

#### 3) multipart/form-data with file upload

```bash
curl -X POST http://localhost:8080/v1/tweets \
  -H "X-API-Token: <XPOST_API_TOKEN>" \
  -F "text=Hello with upload" \
  -F "media=@/absolute/path/image.jpg"
```

## Limits

- Max media files per request: `4`
- Max media size per file: `8 MB`

## Common Errors

- `401 {"error":"invalid api token"}`
- `503 {"error":"api token is not configured"}`
- `503 {"error":"x client is not ready"}`
- `400 {"error":"text or media is required"}`
- `400 {"error":"too many media files, max is 4"}`
- `502 {"error":"...x api error..."}`
