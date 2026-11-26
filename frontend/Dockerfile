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

# The base image runs as uid 101; package management needs root.
USER root

# The base installs four dynamic nginx modules that this image never loads (nginx.conf
# has no load_module and the template uses none of them), and they drag in an XML
# parser, an image toolkit and a JavaScript engine: libxslt/libxml2 for xslt, libgd ->
# fontconfig -> libexpat for image-filter, libGeoIP, and njs itself. This container only
# serves static files and reverse-proxies /api, so none of that belongs in the runtime.
# Alpine has since published fixes for libxml2 (2.13.9-r4 and later) and libexpat
# (2.11.0), but removing the packages still beats carrying parsers nothing calls.
RUN apk del --no-network nginx-module-xslt nginx-module-njs nginx-module-image-filter nginx-module-geoip \
	&& rm -rf /var/cache/apk

# Alpine publishes fixes inside a stable branch well before the nginx project rebuilds a
# tag. The pinned image (built 2026-11-23) still carries zlib 1.3.2-r1, which
# CVE-2026-4738 affects and 1.4-r0 fixes, while the v3.24 index already offers 1.4-r0.
# Patch the packages that have a published fix and keep tracking the rest through the
# tag; musl is not in that group, CVE-2026-107891 is already fixed in the shipped
# 1.2.6-r3 (https://secdb.alpinelinux.org/v3.24/main.json), even though Docker Scout
# reports a fix version that only exists in another branch.
RUN apk upgrade --no-cache zlib

# Back to the unprivileged user the base image expects.
USER 101

COPY --from=build /app/dist/clovance/browser /usr/share/nginx/html
COPY --from=build /app/default.conf.template /etc/nginx/templates/default.conf.template

# Trivy does not map nginx.org packages to CVEs, so nginx itself is invisible to the
# publish-time scan: track it through this tag and the nginx security advisories.

# Expose the default nginx port
EXPOSE 7000

CMD ["nginx", "-g", "daemon off;"]
