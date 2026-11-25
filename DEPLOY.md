# Deploying Nudge to the public internet

Nudge runs locally, but it can be shared publicly in two ways.

> ⚠️ **Security note:** anyone who scans the login QR links *their* WhatsApp and can
> schedule messages from *their own* number — that's the product. The **PIN gate**
> (`NUDGE_PIN`) keeps strangers out of your instance entirely. Always set a strong PIN
> before going public.

---

## Option A — instant public link (tunnel), laptop stays on

1. Start the production server (or dev):

   ```bash
   npm run build && npm run start -- -p 3000
   ```

2. Expose it with a tunnel (pick one):

   ```bash
   # cloudflared (free, no signup)
   cloudflared tunnel --url http://localhost:3000

   # or ngrok (needs a free account/token)
   ngrok http 3000
   ```

3. Share the printed `https://…` URL plus your PIN. Visitors: PIN → scan QR → schedule.

Notes:
- The tunnel terminates when your laptop sleeps/shuts down.
- Each visitor links their own WhatsApp; sessions persist in `.data/wa-sessions/`.

---

## Option B — real 24/7 hosting (recommended for a true public app)

### Railway / Render / any Docker host

1. Push this repo to GitHub.
2. Create a new service → "Deploy from Dockerfile".
3. Set env vars:
   - `NUDGE_PIN` — strong PIN (required)
   - `PUPPETEER_CACHE_DIR=/app/.cache/puppeteer` (optional; keeps Chrome in a writable dir)
4. Mount a **persistent volume** at `/app/.data` — this stores WhatsApp sessions,
   users, and nudges. Without it, every redeploy asks everyone to re-scan.
5. Deploy. Done.

### Fly.io (has free persistent-ish volumes + cheap VMs)

```bash
fly launch --dockerfile Dockerfile
fly volumes create nudge_data --size 3
fly volumes show nudge_data  # note the id, then in fly.toml:
#   [mounts]
#     source = "nudge_data"
#     destination = "/app/.data"
fly secrets set NUDGE_PIN=choose-a-strong-pin
fly deploy
```

### VPS (Ubuntu + Docker)

```bash
git clone <your-repo> && cd <your-repo>
docker build -t nudge .
docker run -d --name nudge -p 80:3000 \
  -v nudge_data:/app/.data \
  -e NUDGE_PIN=choose-a-strong-pin \
  --restart unless-stopped \
  nudge
```

---

## Operational notes

- **WhatsApp sessions are device links.** WhatsApp allows a limited number of linked
  devices per account; inactive links are dropped by WhatsApp after ~14 days of the
  phone being offline. Users may need to re-scan occasionally — this is normal.
- **ToS reality check:** this uses an unofficial WhatsApp Web bridge
  (whatsapp-web.js). For heavy/commercial sending, use the official
  **WhatsApp Cloud API** instead to avoid account bans.
- **Backups:** everything stateful lives in `.data/` — back that volume up.
- **Scale:** one server = one Chrome per active session (~150–300 MB each).
  The slot registry caps concurrent sessions (20) to protect the box.
