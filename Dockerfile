FROM debian:bookworm-slim AS downloader

RUN apt-get update && apt-get install -y curl ca-certificates tar && rm -rf /var/lib/apt/lists/*

WORKDIR /download

RUN curl -sSL https://router.apollo.dev/download/nix/latest | sh


FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=downloader /download/router /usr/local/bin/router
COPY router.yaml /config/router.yaml
COPY supergraph-schema.graphql /config/supergraph.graphql

RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser

EXPOSE 4000

CMD ["router", "--config", "/config/router.yaml", "--supergraph", "/config/supergraph.graphql"]
