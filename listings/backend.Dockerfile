# ── Build stage ────────────────────────────────────────────────
FROM node:20-alpine AS builder

# Pin pnpm to a version compatible with this Node (pnpm@latest is now 11.x,
# which requires Node >= 22) and matching the CI / lockfile (pnpm 10).
RUN corepack enable && corepack prepare pnpm@10.34.3 --activate

WORKDIR /app

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
RUN pnpm install --frozen-lockfile

COPY . .
RUN npx prisma generate && pnpm run build

# Drop dev dependencies so the runtime image ships only production deps. The
# prisma CLI stays (it is a runtime dependency — `prisma migrate deploy` runs
# on container start), as do @prisma/client and the generated client.
RUN pnpm prune --prod

# ── Production stage ──────────────────────────────────────────
FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/src/generated ./src/generated
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/prisma.config.ts ./prisma.config.ts
COPY --from=builder /app/src/common/database-url.ts ./src/common/database-url.ts

# Run as the unprivileged `node` user that ships with the base image. The
# copied app stays root-owned (read-only to the process, which is fine); only
# the uploads tree needs to be writable, so it is owned by `node`. A fresh
# named volume mounted at /app/uploads inherits this ownership on first use.
RUN mkdir -p uploads/products uploads/stores uploads/users \
  && chown -R node:node uploads

USER node

EXPOSE 3000

CMD ["sh", "-c", "npx prisma migrate deploy && node dist/src/main"]
