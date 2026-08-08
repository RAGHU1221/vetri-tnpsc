# வெற்றி TNPSC (Vetri TNPSC) — Phase 1

TNPSC exam prep app — Tamil & English bilingual. Flutter + PHP + MySQL.

## Structure
```
php_api/       PHP backend (Render deploy)
flutter_app/   Flutter app (Android)
```

## Backend deploy (Render + Aiven) — VIVASAYI same pattern
1. Aiven-la new MySQL DB create pannunga: `vetri_tnpsc`
2. `php_api/schema.sql` + all migrations run pannunga (Aiven console query editor) — see Full Deploy Checklist below
3. GitHub-la repo push pannunga
4. Render deploy:
   - **Blueprint:** New → Blueprint → repo select → `render.yaml` reads automatically
   - **Manual:** New Web Service → repo select → Root Directory: `php_api` → Docker
5. Environment variables set pannunga (`.env.example` paarunga): DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS, DB_SSL=true, JWT_SECRET, NVIDIA_API_KEY, CRON_SECRET
6. Deploy! → `https://vetri-tnpsc.onrender.com` test:
   - `GET /` → `{"app":"Vetri TNPSC API","status":"ok"}`
   - `GET /api/subjects` → syllabus JSON (Apache rewrite via `public/.htaccess`)
7. Seed data: local-la `php seed_loader.php` + `php guide_seed_loader.php` run pannunga (env vars set panni) — 216 questions + 14 guides DB-la load aagum

## API endpoints (Phase 1)
| Method | Path | Auth | Description |
|---|---|---|---|
| POST | /api/auth/register | — | name, mobile, password |
| POST | /api/auth/login | — | mobile, password → JWT |
| GET | /api/auth/me | ✅ | current user |
| GET | /api/subjects | — | syllabus tree + counts |
| GET | /api/questions?subject=&important=1 | ✅ | filtered questions |

## Flutter app
1. `flutter_app/lib/src/config/api_config.dart` — Render URL update pannunga
2. `flutter create .` run pannunga flutter_app folder-la (android/ files generate aagum)
3. `flutter pub get` → `flutter run`
4. Offline-first: 120 questions seed JSON asset-la bundle aagirukku — internet illama browse pannalam

## Phase 1 features ✅
- Login / Signup (JWT + secure storage)
- Language toggle தமிழ் ⇄ English (AppBar-la)
- Dashboard 4 tiles (Syllabus + Question Bank live; Mock Test & CA Phase 3)
- Syllabus browser (subject-wise, question counts)
- Question cards: bilingual, tap-to-answer, 🔥/⭐ importance badges, 📖 source book/page, 💡 explanation, years chips
- Noto Sans Tamil font, 18sp, 1.7 line-height (படிக்க easy!)

## Next phases
- Phase 2: Admin import panel (Excel upload — import_template.xlsx)
- Phase 3: Mock test engine (timer, 200Q, scoring)
- Phase 4: Current affairs · Phase 5: Sarvam AI tutor · Phase 6: Gamification

## Phase 2 ✅ — Admin Import System
- `php_api/public/admin/index.html` — Admin panel (SheetJS, browser-side Excel parse)
- Endpoints: POST `/api/admin/import/chunk` (50 rows/chunk, upsert), POST `/api/admin/import/log`, GET `/api/admin/stats`
- `migration_phase2.sql` run pannunga → unga mobile-ku `is_admin = 1` set pannunga
- Panel URL: `https://your-app.onrender.com/admin/`
- Flow: Login → Excel drag-drop → validation preview (valid/invalid counts + errors) → chunked import with progress bar → summary + import log
- Duplicate questions auto-update (upsert on question_ta)
- `years_asked` fill panna: `repeat_count` auto-calculate aagum → app-la 🔥/⭐ badges
- Flutter: QuestionService ippo server-first (API fetch) + seed fallback (offline)

## Phase 3 ✅ — Mock Test Engine
- `migration_phase3.sql` run pannunga (test_results table)
- Test setup: subject chips (Full/mini) + question count slider (10-50) — G4 timing 54 sec/Q
- Test screen: ⏱ countdown timer (last 2 min red), OMR palette navigation, tap-to-answer/deselect, PopScope back-block, ⏰ auto-submit
- Scoring: 1.5 marks/Q (G4 300/200 pattern), accuracy %, server percentile
- Result: score card, correct/wrong/skipped, 📌 weak subjects (>40% wrong), full solution review with explanations + source
- Endpoints: POST `/api/tests/submit`, GET `/api/tests/history`

## Phase 4 ✅ — Current Affairs + Daily Quiz + Reminder
- `migration_phase4.sql` run pannunga (current_affairs table)
- Endpoints: GET `/api/current-affairs?month=&tn=1&category=`, GET `/api/daily-quiz` (date-seeded — everyone same 10 Q daily), POST `/api/admin/ca`
- Admin panel-la 📰 CA entry form (date, தமிழ்/EN title & content, category, TN checkbox)
- App: CA screen — date-grouped cards, category icons, ⭐ TN priority gold border, TN-only filter, ⚡ Daily Quiz FAB (10 Q / 9 min)
- 🔔 Daily 7 PM local notification reminder (flutter_local_notifications — Firebase thevai illa)

### AndroidManifest additions (Phase 4 notifications):
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```
`flutter create .` panna apram ivai manually add pannanum (`android/app/src/main/AndroidManifest.xml`).

## Phase 5 ✅ — AI ஆசிரியர் (Sarvam-M Tamil Tutor)
- `migration_phase5.sql` run pannunga (ai_logs table)
- Render env-la add pannunga: `NVIDIA_API_KEY` (NVIDIA Build → sarvamai/sarvam-m) — **key backend-la mattum, app-la illa!**
- Endpoints: POST `/api/ai/chat` (8-turn history), POST `/api/ai/explain` (question_id → deep explanation + memory trick)
- Rate limit: 30 AI requests/user/day (free credits protection) — limit mudinja friendly Tamil message
- App: 🤖 AI Tutor dashboard tile → chat screen (bubbles, typing indicator, selectable text)
- Solution review-la "🤖 AI-யிடம் மேலும் கேள்" button — question+answer context auto-fill panni chat open aagum
- AI fail aana stored explanation fallback — students-ku eppovum edhavadhu answer kidaikkum

## Phase 6 ✅ — Growth (Streaks · Leaderboard · Progress · Countdown)
- `migration_phase6.sql` run pannunga (user_streaks table)
- Endpoints: POST `/api/streak/ping`, GET `/api/leaderboard?period=week|all`, GET `/api/progress`
- 🔥 Streak: app open panna daily ping — AppBar-la 🔥N badge; miss panna reset
- ⏳ Exam countdown card — Group 4: 20 Dec 2026 (progress_screen.dart-la examDate constant)
- 📊 My Stats: tests taken, avg accuracy, subject-wise accuracy bars (green ≥70 / gold ≥45 / red <45 — weak-first sort)
- 🏆 Leaderboard: weekly top 20 (🥇🥈🥉), unga rank highlight, score+accuracy

## 🎉 PROJECT COMPLETE — All 6 Phases
Full deploy checklist:
1. Aiven DB → schema.sql + all 9 migrations (see Full Deploy Checklist below)
2. Render: use `render.yaml` Blueprint or manual Docker deploy (root: `php_api`)
3. Render env: DB_*, JWT_SECRET, NVIDIA_API_KEY, CRON_SECRET
4. Admin set: UPDATE users SET is_admin=1 WHERE mobile='...'
5. Seed loaders: `php seed_loader.php`, `php guide_seed_loader.php`
6. flutter create . → AndroidManifest permissions → APK build

## 🎨 UI Polish — Professional Button System
- `lib/src/ui/widgets/vetri_buttons.dart` — reusable design system:
  - **VetriButton** — gradient/shadow buttons (primary/danger/gold/outline/ghost), press-scale animation, haptic feedback, loading spinner
  - **VetriChip** — subject filters, gradient when selected
  - **VetriIconButton** — circular gradient icon buttons (AI chat send, logout)
  - **VetriOptionTile** — A/B/C/D answer options with letter-badge, correct/wrong states
- Applied across **all 9 screens**: login, signup, dashboard (gradient tiles), syllabus (icon tiles), test setup, test screen (OMR + nav), question list, test result (AI button), CA (gradient FAB), AI chat (send button)
- Global `main.dart` theme polish: card/dialog/chip/snackbar shapes, elevation-0 flat design, rounded 14-18px corners throughout
- Micro-interactions: tap-scale (0.95-0.97), haptic selection click, animated color/shadow transitions

## Phase 4b ✅ — Current Affairs Daily Auto-Update
- `migration_phase4b.sql` run pannunga
- New endpoint: `GET /api/cron/fetch-ca?token=CRON_SECRET` — pulls from 4 free RSS feeds
  (The Hindu TN, PIB TN, The Hindu National, The Hindu Sci-Tech), auto-translates EN→TA
  via Sarvam-M, dedups by source_url, inserts into `current_affairs`
- Render env: add `CRON_SECRET` (random string)
- Schedule daily via **cron-job.org** (free, no card) — full setup steps in
  `php_api/docs_CA_AUTO_UPDATE.md`
- Manual admin entry (Phase 4) still works — auto-fetch supplements it, doesn't replace it
- Render free-tier cold-start note: first daily cron hit may take ~50s (documented in the guide)

## Phase 1d ✅ — Real-Paper Pattern Support + PYQ Verification
- `migration_phase1c_format.sql` run pannunga (question_format, table_data, assertion/reason, image_url, source_verified columns)
- **Excel bank pre-imported**: `tnpsc_question_bank_v1_verified.xlsx` (120 Q) → merged into `questions_seed.json` (deployed to Flutter asset + PHP seed)
- **PYQ verification (this session)**: Real Group 4 2024 June paper fetched from official-content source, cross-checked against bank:
  - ✅ 1 confirmed exact match tagged (`தமிழ் செம்மொழி 2004` → G4-2024)
  - ✅ 5 NEW real questions added (verbatim from the fetched paper) demonstrating match_table (2) and assertion_reason (2) formats + 1 simple — all `source_verified=1`
  - ⚠️ Full 120-question verification against all years needs much deeper research (suggested via Research feature) — only ~30/1000+ total PYQ questions checked so far. Treat `source_verified=1` as ground truth; `source_verified=0` as syllabus-curated (still correct, but not PYQ-confirmed).
- **Real-paper-pattern rendering**: new `question_body.dart` widget renders:
  - `simple` — plain bilingual question (as before)
  - `match_table` — List I / List II two-column table exactly like TNPSC OMR sheets
  - `assertion_reason` — கூற்று [A] + காரணம் [R] highlighted blocks
  - Question images (`image_url`) shown inline with graceful fallback if missing
  - 🔵 "Real PYQ" badge on `source_verified=1` questions
- Wired into both **question_list_screen** (practice) and **test_screen** (mock test)
- **Admin import template v2** (`import_template_v2.xlsx`, in `php_api/public/admin/`): new columns for format/table_data/assertion/reason/image_url/source_verified — backward compatible with v1 (simple questions still work with old columns)
- Symbols/special Tamil characters: all stored as UTF-8 JSON (`JSON_UNESCAPED_UNICODE` everywhere) — no mangling

## Phase 1e ✅ — Group 2/2A Support (same real-paper pipeline as Group 4)
- **8 real verified Group 2/2A questions** fetched from official-content source (2024 September paper) —
  4 match_table (revolt-area, institutions-location, fundamental rights, presidents-years),
  1 assertion_reason (small-scale industries), 3 simple — all `source_verified=1`, tagged `G2A-2024`
- Covers: history, polity, economy, current_affairs (degree-level Group 2/2A syllabus)
- **`group_exam` field** added throughout: Question model, TestConfig, PHP QuestionController
- **Dashboard exam-group switcher** — 📗 Group 4 / 📘 Group 2/2A chips; switching instantly
  re-filters syllabus, question bank, and mock tests (all client-side, works offline)
- `questions_seed.json` v3: 133 total (125 G4 + 8 G2A) — single asset bundles both, app filters live
- PHP `/api/questions` and `/api/subjects` accept optional `?group_exam=G4|G2A` — app fetches
  the full multi-group set once and filters locally for instant offline switching
- Same honesty caveat as Group 4: 8 questions is a starting sample (~10% of one paper), not
  exhaustive coverage — Group 2/2A syllabus is much broader (degree-level GS + aptitude)

## Phase 1f ✅ — NMMS (8th std scholarship exam) support
- **83 real verified NMMS questions** imported (`group_exam=NMMS`, `source_verified=1`) —
  topic: பணம் (Origin & Evolution of Money), from official-content source (trbexam.com)
- ⚠️ Honest note: This set is **Economics/Money**, not History — real NMMS History-specific
  content exists only as PDF downloads (Google Drive/blogspot links) across every source checked;
  none had inline-extractable text, so no History questions were added (avoiding fabrication).
  If you have an NMMS History PDF, upload it — MarkItDown + pyq_matcher.py pipeline (built in
  Phase 1) can extract it properly instead of guessing.
- Dashboard now has **3-way exam switcher**: 📗 Group 4 · 📘 Group 2/2A · 📙 NMMS (8th)
- Total bank: 216 questions (125 G4 + 8 G2A + 83 NMMS)

## Phase 1g ✅ — வழிகாட்டி (Guide) — All-Exams Directory
- `migration_phase_guide.sql` run pannunga (exam_guides table)
- **9 exams documented** (real, verified 2026 data — age limits, patterns, syllabus, salary):
  - 🏛️ Govt Jobs: TNPSC Group 4/VAO, TNPSC Group 2/2A, TN Police Constable, TN Police SI
  - 🏦 Competitive: IBPS PO, IBPS Clerk
  - 📚 School: NMMS, TN 10th (SSLC), TN 12th (HSC)
- `guide_seed_loader.php` — loads `exam_guides_seed.json` into MySQL
- New dashboard tile: **வழிகாட்டி** — 3-tab list (Govt Jobs / Competitive / School) → detail screen
  with eligibility, age limit, exam pattern, syllabus, selection process, salary, official website,
  and prep tips — bilingual throughout
- Endpoints: `GET /api/guides?category=`, `GET /api/guides/{key}`, `POST /api/admin/guides` (admin upsert)
- Offline-first: `assets/data/exam_guides.json` bundled — works without internet
- ⚠️ Note: exam patterns/eligibility change yearly — dates/ages sourced from 2026 notifications;
  always double-check tnpsc.gov.in / tnusrb.tn.gov.in / ibps.in / dge.tn.gov.in before students rely on it for applying

---

# 🎉 PROJECT STATUS — Complete Feature List

| # | Feature | Status |
|---|---|---|
| 1 | Auth (JWT) + bilingual UI + Syllabus browser | ✅ |
| 2 | Admin Excel import panel (SheetJS, chunked) | ✅ |
| 3 | Mock Test Engine (OMR, timer, weak-topic detection) | ✅ |
| 4 | Current Affairs + Daily Quiz + auto-fetch cron + push reminder | ✅ |
| 5 | 🤖 Sarvam AI ஆசிரியர் (rate-limited, secure) | ✅ |
| 6 | Streaks + Leaderboard + Progress + Exam Countdown | ✅ |
| — | Professional gradient button design system | ✅ |
| — | Real-paper pattern rendering (match-table, assertion-reason, images) | ✅ |
| — | Multi-exam support: TNPSC G4 (125Q) + G2A (8Q) + NMMS (83Q) | ✅ |
| — | வழிகாட்டி — 9-exam guide directory (jobs + school exams) | ✅ |

**Total question bank: 216 verified/curated questions across 3 exam groups**
**Total exam guides: 9 (govt jobs, banking, school exams)**

## 🚀 Full Deploy Checklist
1. Aiven MySQL → run **all migrations in order**:
   `schema.sql`, `migration_phase2.sql`, `migration_phase3.sql`, `migration_phase4.sql`,
   `migration_phase4b.sql`, `migration_phase1c_format.sql`, `migration_phase5.sql`,
   `migration_phase6.sql`, `migration_phase_guide.sql`, `migration_phase_guide2.sql`
2. Render deploy (pick one):
   - **Blueprint (recommended):** Render → New → Blueprint → connect repo → `render.yaml` auto-configures service
   - **Manual:** Render → New Web Service → repo → Root Directory: `php_api` → Docker
3. Render env vars: `DB_HOST/PORT/NAME/USER/PASS/SSL`, `JWT_SECRET`, `NVIDIA_API_KEY`, `CRON_SECRET`
   (Blueprint auto-generates `JWT_SECRET` and `CRON_SECRET`; set DB + NVIDIA keys manually)
4. Health check: `GET https://vetri-tnpsc.onrender.com/` → `{"app":"Vetri TNPSC API","status":"ok"}`
   Also test: `GET /api/subjects` → JSON syllabus tree (requires `.htaccess` rewrite — included in repo)
5. Admin: `UPDATE users SET is_admin=1 WHERE mobile='YOUR_MOBILE'`
6. Run seed loaders locally (env vars set): `php seed_loader.php`, `php guide_seed_loader.php`
7. cron-job.org → daily hit `/api/cron/fetch-ca?token=...` at 6:30 AM IST
8. Flutter: `flutter create .` → add AndroidManifest permissions (notifications) →
   change `MainActivity` to `FlutterFragmentActivity` (biometric fix) → `flutter pub get` → build APK
9. Admin panel: `https://vetri-tnpsc.onrender.com/admin/` → import `tnpsc_question_bank_v1_verified.xlsx`

## Phase 1h ✅ — வழிகாட்டி: 12th-க்குப் பிறகு (After 12th Career Guide)
- `migration_phase_guide2.sql` run pannunga (adds 'after_12th' to category ENUM)
- **5 new guides** (real, web-verified 2026 data):
  - ⚙️ Engineering (TNEA) — with **real cutoff formula**: Maths + Physics/2 + Chemistry/2
  - ⚕️ Medical (NEET) — clarifies TN medical admission is now NEET-score-only (not 12th cutoff)
  - 💻 **IT/Software courses** — B.Tech CSE/IT, BCA, B.Sc CS/IT, Diploma — eligibility/pattern/scope
  - 🎓 Arts & Science (B.A/B.Sc/B.Com) — TNSCAS counselling process
  - 🔧 Polytechnic Diploma — 10th-based entry + lateral entry info
- **🧮 Live TNEA Cutoff Calculator** (`cutoff_calculator_screen.dart`) — real-time calculation from
  Maths/Physics/Chemistry marks, shows score/200 + a general range indicator (🟢🔵🟡🟠🔴)
  — clearly disclaimed as comparative-only, NOT a specific college guarantee (cutoffs vary by
  category/district/round — directs to tneaonline.org for the real numbers)
- Guide list now has **4th tab**: 🎓 12th-க்குப் பிறகு / After 12th
- Calculator accessible from the Engineering guide detail page ("🧮 என் Cutoff கணக்கிடு" button)
- Total guides: 14 (4 govt jobs + 2 competitive + 3 school exams + 5 after-12th)
