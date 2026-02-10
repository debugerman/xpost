FROM golang:1.22-alpine AS builder

WORKDIR /src

ARG TARGETOS=linux
ARG TARGETARCH=amd64

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -trimpath -ldflags="-s -w" -o /out/xpost .

FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /app

ENV XPOST_ADDR=:8080

COPY --from=builder /out/xpost /app/xpost

EXPOSE 8080

ENTRYPOINT ["/app/xpost"]
