# Nudge — WhatsApp Automation & Scheduled Delivery

Nudge sends your WhatsApp messages at exactly the right time. Log in using either **WhatsApp Web QR Code** (instant camera scan) or an **8-character pairing code** on your phone. Schedule "nudges" with text and attachments (photos, videos, audio, PDFs) that are delivered automatically from your own WhatsApp.

Runs 100% locally with high-performance SQLite storage and optimized browser automation.

---

## What's New & Upgraded

1. ⚡ **High-Speed WhatsApp Web Initialization**:
   - **OneDrive I/O Isolation**: Bypasses cloud sync lock contention on Windows by maintaining browser caches in a local high-speed directory.
   - **System Chrome Discovery**: Automatically detects installed Google Chrome or Microsoft Edge, launching in ~1.5–2 seconds.
   - **Optimized Chromium Arguments**: Strips audio/extension/backgrounding overhead to bring QR codes to your screen instantly.
   - **Live Progress Telemetry**: Visual step-by-step progress and sync percentage as WhatsApp loads.

2. 🗄️ **High-Performance SQLite Database**:
   - Embedded SQLite with Write-Ahead Logging (WAL) and indexed tables for `users` and `messages`.
   - Replaced flat JSON read/write file locks with atomic, ACID-compliant database operations.
   - Automatic migration of legacy `users.json` and `messages.json`.

3. 🎨 **Modernized Frontend System Design**:
   - **Tabbed Login Screen**: Effortlessly toggle between **Scan QR Code** (with scanner guides and live countdown) and **Link with Phone Number** (with click-to-copy pairing code).
   - **Dashboard Overview Bar**: Real-time stats for Total Nudges, Pending, Delivered, and Failed counts.
   - **Smart Time Presets**: One-click shortcuts for `+15m`, `+1h`, `Tomorrow 9 AM`, and `Tomorrow 6 PM`.
   - **Search & Filter Tabs**: Filter messages by status (`All`, `Pending`, `Sent`, `Failed`, `Cancelled`) and search by recipient or message text.
   - **Live WhatsApp Health Card**: In-dashboard connection monitoring and instant re-linking.

---

## Getting Started

### Local Setup

```cmd
start.cmd
```

or with Node on PATH:

```bash
npm run dev -- --port 3000
```

Open [http://localhost:3000](http://localhost:3000):

1. **Log in**: Scan the displayed WhatsApp Web QR code using your phone (`WhatsApp → Settings/Menu → Linked Devices → Link a device`), or switch to "Link with Phone Number".
2. **Dashboard**: Schedule your nudges, attach media if needed, and let Nudge deliver your messages automatically.

---

## Project Structure

```
src/
  app/
    page.tsx                   # Login UI (QR scanner, phone pairing, stage telemetry)
    dashboard/page.tsx         # Dashboard (stats, smart presets, filters, live engine status)
    api/auth/route.ts          # Auth status & auto-login upon WhatsApp session readiness
    api/wa/route.ts            # WhatsApp engine control (status, QR, stage progress)
    api/wa/pair/route.ts       # 8-character pairing code generation
    api/messages/route.ts      # List & schedule nudges
    api/messages/[id]/route.ts # Cancel & delete nudges
    api/uploads/route.ts       # Secure attachment uploads
  lib/
    db.ts                      # SQLite connection, WAL mode, schema & legacy migration
    store.ts                   # Strongly typed database operations (users & messages)
    whatsapp.ts                # Multi-slot high-speed WhatsApp engine & Chrome auto-discovery
    paths.ts                   # Path resolutions & OneDrive I/O safety bypass
    scheduler.ts               # Background message dispatch loop
    auth.ts                    # Session token verification & cookie security
    time.ts                    # 12-hour AM/PM formatting & calendar helpers
  types/
    sqlite.d.ts                # TypeScript declarations for Node.js SQLite
```
