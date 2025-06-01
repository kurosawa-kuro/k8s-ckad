# ---- build stage ----
FROM golang:1.22 AS builder
WORKDIR /go/src/app           # GOPATH 内
COPY . .

# モジュールを無効化してビルド
ENV GO111MODULE=off
RUN go build -o /app .

# ---- runtime stage ----
FROM gcr.io/distroless/base-debian12
ENV SUN_CIPHER_ID=5b9c1065-e39d-4a43-a04a-e59bcea3e03f
COPY --from=builder /app /app
ENTRYPOINT ["/app"]
