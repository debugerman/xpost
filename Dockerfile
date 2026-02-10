FROM golang:1.23-alpine AS builder

WORKDIR /app

ARG TARGETOS=linux
ARG TARGETARCH=amd64

# Install tools and runtime data for scratch image.
RUN apk add --no-cache upx tzdata ca-certificates

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -trimpath -ldflags="-s -w" -o /out/xpost . && \
    upx --best --lzma /out/xpost || true

FROM scratch

# Certificates for HTTPS requests.
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Timezone database.
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Application binary.
COPY --from=builder /out/xpost /xpost

ENV XPOST_ADDR=:8080
ENV TZ=UTC

EXPOSE 8080

ENTRYPOINT ["/xpost"]
