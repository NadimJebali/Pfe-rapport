# ── Build stage ────────────────────────────────────────────────
FROM node:20-alpine AS builder

# Pin pnpm to a version compatible with this Node (pnpm@latest is now 11.x,
# which requires Node >= 22) and matching the CI / lockfile (pnpm 10).
RUN corepack enable && corepack prepare pnpm@10.34.3 --activate

WORKDIR /app

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

ENV VITE_API_URL=__VITE_API_URL_PLACEHOLDER__
ENV VITE_STRIPE_PUBLISHABLE_KEY=__VITE_STRIPE_PUBLISHABLE_KEY_PLACEHOLDER__

RUN pnpm run build

# ── Production stage ──────────────────────────────────────────
# Unprivileged nginx: runs as uid 101 and listens on 8080 (no root, no
# privileged port). Caddy reaches it on :8080 over the internal network.
FROM nginxinc/nginx-unprivileged:alpine

# Setup needs root (chmod the entrypoint, make the SPA assets writable so the
# entrypoint can substitute the runtime VITE_* placeholders); then drop back.
USER root
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh \
  && chown -R 101:101 /usr/share/nginx/html
USER 101

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]

EXPOSE 8080
