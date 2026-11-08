FROM node:24 AS build

WORKDIR /app
ENV CI=true

RUN corepack enable
RUN corepack prepare pnpm@12.18.0 --activate

COPY package.json package.json
COPY pnpm-lock.yaml pnpm-lock.yaml
COPY pnpm-workspace.yaml pnpm-workspace.yaml

RUN pnpm install --frozen-lockfile --ignore-scripts \
	&& pnpm approve-builds @parcel/watcher esbuild lmdb msgpackr-extract \
	&& pnpm rebuild @parcel/watcher esbuild lmdb msgpackr-extract

COPY . .

RUN ./node_modules/.bin/ng build

# Runs as uid 101 (nginx) by default: pid, temp paths and cache live in /tmp and the
# image's entrypoint needs no root privileges. The stock nginx:alpine image cannot be
# started with a non-root USER because its config writes pid and cache under /var.
FROM nginxinc/nginx-unprivileged:alpine

COPY --from=build /app/dist/clovance/browser /usr/share/nginx/html
COPY --from=build /app/default.conf.template /etc/nginx/templates/default.conf.template

# The upstream base (built 2026-10-19) predates the October security releases and still
# ships packages with fixable CVEs, so a plain rebuild is not enough:
#   - ca-certificates 20260909-r0 -> 20261020-r0: still trusts "emSign ECC Root CA - G3",
#     one of the roots of the compromised eMudhra intermediates (CVE-2026-111943). The
#     bundle is what curl/wget validate outbound TLS against.
#   - brotli-libs 1.2.0-r1 -> 1.2.1-r0: out-of-bounds write in the decoder (CVE-2026-111497).
#   - curl/libcurl 8.22.0-r0 -> 8.23.0-r0 and libexpat 2.9.0-r0 -> 2.10.0-r0.
# Keep this list explicit rather than `apk upgrade` so a routine package bump cannot
# change nginx behaviour unnoticed. Placed last so the COPY layers stay cached.
# The base image runs as uid 101, so root is needed for the package database.
USER root
RUN apk upgrade --no-cache ca-certificates brotli-libs curl libcurl libexpat
USER 101

# Expose the default nginx port
EXPOSE 7000

CMD ["nginx", "-g", "daemon off;"]
