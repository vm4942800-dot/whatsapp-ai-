# Nudge — production image (multi-stage; puppeteer's bundled Chrome needs these libs)

FROM node:22-slim AS base
# Chrome for Testing dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates fonts-liberation libasound2 libatk-bridge2.0-0 libatk1.0-0 \
    libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 \
    libgcc1 libglib2.0-0 libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 \
    libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 \
    libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 \
    wget xdg-utils \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Where puppeteer stores its Chrome (same path in build + runtime so the
# browser downloaded at build time is found when the app runs).
ENV PUPPETEER_CACHE_DIR=/app/.cache/puppeteer

# --- deps + build ---
FROM base AS build
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# --- runtime ---
FROM base AS runtime
ENV NODE_ENV=production
ENV PUPPETEER_SKIP_DOWNLOAD=false
COPY --from=build /app/package.json /app/package-lock.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/.cache/puppeteer ./.cache/puppeteer
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/next.config.ts ./next.config.ts

# Persistent data: WhatsApp sessions + users + nudges live here.
# Mount a volume on /app/.data in production!
RUN mkdir -p /app/.data
VOLUME ["/app/.data"]

EXPOSE 3000
# Railway (and most hosts) inject PORT; default to 3000 locally.
CMD ["sh", "-c", "npm run start -- -p ${PORT:-3000}"]
