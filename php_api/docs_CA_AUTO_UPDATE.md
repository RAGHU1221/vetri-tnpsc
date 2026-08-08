# Current Affairs — Daily Auto-Update Setup

## How it works
1. `CronCAController::fetchDaily()` — new endpoint `GET /api/cron/fetch-ca?token=...`
2. Pulls latest headlines from **4 free RSS feeds** (no API key, no cost):
   - The Hindu — Tamil Nadu section (⭐ TN priority)
   - PIB (Press Information Bureau) — Tamil Nadu regional releases (⭐ TN priority)
   - The Hindu — National
   - The Hindu — Science & Tech
3. Skips entertainment/gossip noise (movie reviews, box office, horoscope)
4. **Auto-translates English → Tamil** using the same Sarvam-M AI you already use
   for the AI tutor (Phase 5) — so title_ta/content_ta fill automatically
5. Dedup: checks `source_url` before inserting — same article never added twice
6. Max 5 items per feed per run (~20 items/day max) — keeps AI translation cost low

## Setup steps

### 1. Run the migration
```sql
-- migration_phase4b.sql
ALTER TABLE current_affairs MODIFY source_url VARCHAR(500);
ALTER TABLE current_affairs ADD INDEX idx_source_url (source_url(191));
```

### 2. Set the cron secret (Render env vars)
Add a new environment variable:
```
CRON_SECRET=<generate a long random string — e.g. openssl rand -hex 20>
```
This stops random people from spamming your fetch endpoint.

### 3. Test manually first
Visit in browser (replace with your values):
```
https://vetri-tnpsc.onrender.com/api/cron/fetch-ca?token=YOUR_CRON_SECRET
```
Expected response:
```json
{"ok":true,"date":"2026-07-26 07:00","added":12,"skipped_existing":0,"feeds_checked":4,"errors":[]}
```
If `errors` mentions a feed being unreachable, that specific RSS URL may have changed —
open it directly in a browser to confirm, and swap the URL in `CronCAController::FEEDS`
if needed (news sites occasionally restructure their RSS paths).

### 4. Schedule it — free external cron (Render free tier has no built-in cron)
Use **cron-job.org** (free, reliable, no card needed):
1. Sign up at https://cron-job.org
2. Create new cronjob:
   - URL: `https://vetri-tnpsc.onrender.com/api/cron/fetch-ca?token=YOUR_CRON_SECRET`
   - Schedule: daily, e.g. **6:30 AM IST** (so content is ready before students' morning study)
   - ⚠️ Render free web services sleep after 15 min idle — the *first* cron hit of the
     day may take ~50 sec (cold start) before responding. cron-job.org's default
     timeout (30s) might show "failed" even though it actually worked. Set the
     cron-job.org request timeout to 60s if that option is available, or just ignore
     an occasional false "failed" status — check your DB/admin panel to confirm it ran.

### 5. Verify in the app
Open the app → Current Affairs screen → today's date should show new auto-fetched items,
mixed with any you added manually via the admin panel (both work together).

## Cost note
Each run does up to ~20 translation calls to NVIDIA Sarvam-M (title + short content per
item). This is separate from your `ai_logs` rate limit (that's per-user chat/explain only)
— the cron job isn't tied to a user, so it doesn't count against anyone's 30/day limit.
Keep an eye on your NVIDIA Build usage dashboard if you're on a free/credit-limited tier.

## Admin panel still works as-is
Manual entry (Phase 4's 📰 CA form) is untouched — use it for anything the RSS feeds miss
(state government announcements, TNPSC's own notifications, etc.). Auto-fetch and manual
entry both write to the same `current_affairs` table.
