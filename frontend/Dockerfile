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
#
# Pinned rather than floating on `alpine` so that a base change is a visible diff and
# Dependabot can bump it. Note the image moved from the `nginxinc/` namespace, whose
# `alpine` tag has been frozen on nginx 1.31.7 since 2026-10-19, to `nginx/`; 1.31.7 is
# affected by the advisories fixed in 1.31.9 and 1.31.10 (see
# https://nginx.org/en/security_advisories.html).
FROM nginx/nginx-unprivileged:1.31.10-alpine3.24

COPY --from=build /app/dist/clovance/browser /usr/share/nginx/html
COPY --from=build /app/default.conf.template /etc/nginx/templates/default.conf.template

# No `apk upgrade` step on purpose: this base already carries the Alpine fixes for
# ca-certificates (CVE-2026-111943), brotli-libs (CVE-2026-111497), curl/libcurl,
# libexpat, musl (CVE-2026-107891) and zlib (CVE-2026-85091), and a Trivy scan with
# --severity HIGH,CRITICAL --ignore-unfixed comes back clean. Keep it that way by
# bumping the pinned tag instead of patching packages here.
#
# Trivy does not map nginx.org packages to CVEs, so nginx itself is invisible to the
# publish-time scan: track it through this tag and the nginx security advisories.

# Expose the default nginx port
EXPOSE 7000

CMD ["nginx", "-g", "daemon off;"]
