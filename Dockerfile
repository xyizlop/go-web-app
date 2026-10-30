# build
FROM golang:1.27 AS builder

WORKDIR /usr/src/app

COPY go.mod ./

RUN go mod download

COPY main.go .
COPY static/ static/

RUN CGO_ENABLED=0 go build -v -o /usr/local/bin/go-web-app ./...

# prod
FROM gcr.io/distroless/static-debian13

COPY --from=builder /usr/src/app/static/ static/
COPY --from=builder /usr/local/bin/go-web-app /

EXPOSE 8080

CMD ["/go-web-app"]
