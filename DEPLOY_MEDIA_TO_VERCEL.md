# Videos + 3D on Vercel, small APK on the phone

## Short answer

| What | Where it lives |
|------|----------------|
| **Flutter APK** | You build on PC → send **one `.apk` file** to friends (WhatsApp, USB, Drive). **Not** deployed to Vercel. |
| **3D `.glb` + reel `.mp4`** | Hosted on **Vercel** (HTTPS links). |
| **Phone with APK** | Opens app → **downloads** 3D/video over Wi‑Fi/mobile data from Vercel. |

You do **not** deploy the whole Flutter app to Vercel. Only the **shop website `public/` folder** (static files + JSON catalog).

---

## Architecture

```
GitHub (code)  →  Vercel deploy (website)  →  CDN URLs
                                              ↑
Flutter APK (small) ─── internet ─────────────┘
```

---

## Step 1 — Put files on disk (already on your PC)

| Content | Source folder |
|---------|----------------|
| 3D kurta/shalwar | `App/landing page product/kurta/` and `shalwar kameez/` |
| Fabric images | `App/landing page product/fabric/` |
| Reel videos | `App/assets/reels_videos/*.mp4` (use compressed clips, not 4K if possible) |

---

## CDN folder on GitHub (main source)

All large files live here (not in `App/`):

```
E:\fyp whole backend\vercel-cdn-media\
```

Pushed to: https://github.com/Nauman-Irshad/fyp-web-code-deployment/tree/main/vercel-cdn-media

## Step 2 — Sync to website `public/` (for Vercel)

```powershell
cd "E:\fyp whole backend\scripts"
.\sync_cdn_to_figma_public.ps1
```

This copies:

- `landing page product/` → `website .../Figma Design for Frontend/public/landing page product/`
- writes `public/app-models-catalog.json`
- you should **manually copy** reels:

```powershell
$pub = "E:\fyp whole backend\website +dashboard front deployed\Figma Design for Frontend\public"
New-Item -ItemType Directory -Path "$pub\reels_videos" -Force
Copy-Item "E:\fyp whole backend\App\assets\reels_videos\*.mp4" "$pub\reels_videos\" -Force
```

Optional: add `public/reels-catalog.json`:

```json
{
  "cdnBase": "https://fyp-web-code-deployment-flea.vercel.app",
  "videos": [
    { "id": 1, "title": "Kurta stitching", "url": "/reels_videos/tailor1.mp4" }
  ]
}
```

---

## Step 3 — GitHub (code + media)

**Option A — Recommended for FYP (Git LFS for big files)**

```powershell
cd "E:\fyp whole backend\website +dashboard front deployed\Figma Design for Frontend"
git lfs install
git lfs track "*.glb" "*.mp4"
git add .gitattributes
git add public/
git commit -m "Add 3D models and reels for Vercel CDN"
git push
```

GitHub blocks single files **> 100 MB**. Compress 4K reels or use LFS.

**Option B — Code on GitHub, media only via Vercel CLI (no huge push)**

- Push only `app-models-catalog.json` + small images to GitHub.
- Deploy large `public/` folder with [Vercel CLI](https://vercel.com/docs/cli) from your PC (does not require every MB on GitHub).

```powershell
npm i -g vercel
cd "E:\fyp whole backend\website +dashboard front deployed\Figma Design for Frontend"
vercel --prod
```

---

## Step 4 — Vercel

1. Vercel project = your **main shop** (`fyp-web-code-deployment-flea`).
2. Connect same GitHub repo OR deploy with CLI.
3. After deploy, test in browser:

| URL | Should open/download |
|-----|----------------------|
| `https://fyp-web-code-deployment-flea.vercel.app/app-models-catalog.json` | JSON list |
| `https://fyp-web-code-deployment-flea.vercel.app/landing%20page%20product/kurta/black%20kurta%20.glb` | GLB file |
| `https://fyp-web-code-deployment-flea.vercel.app/reels_videos/tailor1.mp4` | Video |

---

## Step 5 — Build small APK

```powershell
cd "E:\fyp whole backend\App"
flutter clean
flutter pub get
flutter build apk --release --split-per-abi
```

Send to anyone: `build\app\outputs\flutter-apk\app-arm64-v8a-release.apk`

App uses CDN: `https://fyp-web-code-deployment-flea.vercel.app` (see `studio_config.dart`).

Change CDN:

```powershell
flutter build apk --release --dart-define=STUDIO_API_BASE=https://YOUR.vercel.app
```

---

## What the APK downloads automatically

| Feature | Vercel path |
|---------|-------------|
| 3D products | `app-models-catalog.json` + `landing page product/.../*.glb` |
| Reels | `reels_videos/*.mp4` |
| Fabric images | `landing page product/fabric/*.webp` |

**Internet required** for 3D and reels after install.

---

## Vercel size limits (important)

- Hobby deploy: large `public/` (hundreds of MB) can be slow or hit limits.
- If deploy fails: compress videos (720p), or host MP4 on **Firebase Storage / Supabase Storage** and put full `https://...` URLs in `reel_media.dart` and `app-models-catalog.json`.

---

## Checklist

- [ ] GLB + fabric in `Figma.../public/landing page product/`
- [ ] MP4 in `public/reels_videos/`
- [ ] `app-models-catalog.json` generated
- [ ] Vercel redeployed, URLs work in browser
- [ ] New slim APK built and tested on phone with Wi‑Fi
