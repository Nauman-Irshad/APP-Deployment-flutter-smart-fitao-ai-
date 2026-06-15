# SmartFitao — full app on Edge (one command)

No APK. Everything runs on your PC in the browser.

## Single command

```powershell
cd "E:\fyp whole backend\App"
.\RUN-EDGE-FULL.ps1
```

This will:

1. Open **5 backend windows** (do not close them)
2. Open **http://127.0.0.1:65106** in Edge — full user marketplace app

---

## What runs where

| Service | Port | Used for |
|---------|------|----------|
| Size prediction (Flask) | **5001** | Live measurement → kurta size |
| Computer vision (camera) | **5003** | Body scan / pose camera |
| 2D try-on API | **8765** | Run Try-On on kurta photo |
| Stripe (Django) | **8000** | Checkout / Pay |
| NLP chatbot API (optional) | **5002** | Extra chat API (app also has bundled chat) |
| **Flutter user app** | **65106** | Home, 3D, Reels, 2D Try On, Cart, **Chat**, Profile |

3D models + reels: **Cloudflare R2 CDN** (internet).

Tailor messages: **Firebase** inside the app (Chat tab + try-on → tailor flow). Internet + Firebase config required.

---

## User journey (test order)

1. **Home** — pick a kurta (3D rotate)
2. **Live measurement** — height/weight → **Size prediction** (local :5001)
3. **Camera** — allow webcam → **Go to 2D Try On** → lands on **2D Try On** tab with your photo
4. **2D Try On** tab — pick kurta → **Run Try-On**
5. **Chat** tab — AI clothing bot; message tailor (demo login below)
6. **Cart / Pay** — Stripe test card `4242 4242 4242 4242`

---

## Demo logins

See `DEMO-ACCOUNTS.md` in this folder if present. Typical:

- User: `ali@smartfitao.pk`
- Tailor: `tailor.ahmed@smartfitao.pk`

---

## Options

```powershell
.\RUN-EDGE-FULL.ps1 -BackendsOnly    # only start servers, no Flutter
.\RUN-EDGE-FULL.ps1 -SkipNlp         # skip NLP window (faster; chat still in app)
.\RUN-EDGE-FULL.ps1 -SkipStripe      # no payment server
```

---

## If port 65106 is already in use

Script opens the existing app instead of crashing. To fully restart:

1. In the Flutter terminal press **`q`**
2. Run `.\RUN-EDGE-FULL.ps1` again

Or press **`R`** (capital R) in Flutter terminal after code changes.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `DartWorker` / compiler exited | `.\RUN-FIX-FLUTTER.ps1` then `.\RUN-EDGE-FULL.ps1` (only one `flutter run`) |
| Size timeout | Wait 60–90s first time; check **Size :5001** window |
| Camera Vercel login | Use `RUN-EDGE-FULL.ps1` — CV is **local :5003** |
| 2D Try-On no photo | Camera → **Go to 2D Try On** again (not old URL handoff) |
| Pay fails | Stripe window **:8000** must be running; internet for `api.stripe.com` |
| Chat empty | Internet; Firebase; or wait for NLP **:5002** if using remote chat URL |

---

## Other scripts (you usually do NOT need these)

| Script | When |
|--------|------|
| `RUN-EDGE-FULL.ps1` | **Default — use this** |
| `RUN-EDGE-LOCAL-BACKEND.ps1` | Backends only (no Flutter) |
| `RUN-EDGE-MARKETPLACE.ps1` | Flutter only (backends already running) |
| `RUN-BUILD-APK-LIVE.ps1` | Phone APK — **skip for Edge-only work** |
