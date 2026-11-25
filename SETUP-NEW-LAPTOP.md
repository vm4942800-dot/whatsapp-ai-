# Nudge — setup on a new laptop

This package contains the complete Nudge app (WhatsApp message scheduler —
"your message, at the right moment"). Your WhatsApp sessions and secrets are
**not** included on purpose: each laptop links its own WhatsApp by entering a
one-time code on the phone (no QR needed).

## One-click start (Windows)

1. Copy this whole folder anywhere on the new laptop (e.g. `Desktop\Nudge`).
2. Double-click **`install-and-run.cmd`**.

That's it. On first run the installer:

- finds Node.js on the PC — system install, the Python `nodejs-wheel`
  runtime, or a copy it downloaded itself; if none exists it downloads a
  portable Node 24 to `%LOCALAPPDATA%\Nudge\node` (no admin rights needed),
- runs `npm install` once (a few minutes — it also fetches the browser
  engine used by WhatsApp Web),
- starts Nudge on **http://localhost:3000** and opens it in your browser.

Every later run: double-click again — it skips straight to launching and
opens the app (also detects if Nudge is already running). If a production
build exists (`.next\BUILD_ID`) it runs the fast production server;
otherwise it falls back to dev mode.

Keep the black console window open while using Nudge; close it (or Ctrl+C)
to stop.

## First login

1. Enter the access PIN (default `1234` — see below to change).
2. Type your WhatsApp number (with country code), then on the phone you
   want to send from open **WhatsApp → Settings → Linked devices →
   Link with phone number instead** and enter the 8-character code shown.
   That WhatsApp number becomes the account — no email/password, no QR.
3. Schedule a nudge (date + 12-hour AM/PM time). It sends automatically
   from your WhatsApp at the right moment.

## Change the access PIN

Set the `NUDGE_PIN` environment variable before starting, e.g.:

```cmd
set NUDGE_PIN=your-secret-code
install-and-run.cmd
```

## Manual setup (any OS, if you prefer)

```bash
npm install
npm run dev -- --port 3000
```

Open http://localhost:3000. On Windows, `start.cmd` is a minimal launcher
that also picks up the Python `nodejs-wheel` Node runtime if present.

## Make it public (optional)

- Instant shareable link (laptop must stay on): double-click
  **`public-link.cmd`** — it starts Nudge if needed, creates a fresh
  Cloudflare quick tunnel, prints the URL, copies it to your clipboard and
  opens it. Quick-tunnel URLs change every restart.

- **Self-healing public link (recommended):** a Windows Task Scheduler task
  (`NudgeAlwaysOn-5min`) runs **`nudge-check-once.cmd`** every 5 minutes and
  once at logon (via the `Nudge Always On` Startup shortcut). Each cycle:
  restarts the app if dead, checks the public link **from the outside**,
  replaces zombie tunnels with a fresh one, and writes the current URL to
  **`Desktop\Nudge-URL.txt`**. It also updates the landing page's app URL
  (`landing/index.html` + `landing/config.json`) automatically, so the
  "Open Nudge" button never goes stale. There is no long-lived process to
  die — Windows itself does the looping. Recreate the task with:

  ```bat
  schtasks /create /tn "NudgeAlwaysOn-5min" ^
    /tr "wscript.exe \"<folder>\run-hidden.vbs\" \"<folder>\nudge-check-once.cmd\"" ^
    /sc minute /mo 5 /rl limited /f
  ```

- Permanent 24/7 hosting (laptop can be off): see `DEPLOY.md` (Docker image
  included).

## Folder guide

```
src/                  app source (Next.js)
public/               logo + static files
install-and-run.cmd   one-click installer + launcher (Windows)
nudge-check-once.cmd  single health-check cycle (Task Scheduler runs this)
nudge-always-on.cmd   classic 60s watchdog loop (manual alternative)
public-link.cmd       instant fresh public link + copy to clipboard
run-hidden.vbs        windowless launcher used by the scheduled task
start.cmd             minimal dev-server launcher (Windows)
Dockerfile            production container image
DEPLOY.md             public-hosting guide (tunnel, Railway/Render, Fly.io, VPS)
```

## Notes

- Everything stateful (WhatsApp sessions, users, nudges, uploads) lives in
  **`%LOCALAPPDATA%\Nudge\data`** on Windows — deliberately outside any
  OneDrive-synced folder, because sync placeholders/locks corrupt Chrome
  session profiles and crash builds. Elsewhere (or if `NUDGE_DATA_DIR` is
  unset) it falls back to `.data/` in the project. Delete the folder to
  factory-reset.
- The downloaded portable Node lives in `%LOCALAPPDATA%\Nudge\node`; delete
  that folder to force a fresh download.
- Unofficial WhatsApp Web bridge (whatsapp-web.js): great for personal use;
  use the official WhatsApp Cloud API for heavy/commercial sending.
