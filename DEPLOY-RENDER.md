# Deploy backends for SmartFitao (Render + Vercel)

Your Flutter app (web / APK / Edge) talks to **remote** APIs — nothing heavy runs inside the app.

---

## 1. Size prediction — **Render** (required)

**Folder:** `pifuhd-main/Ai Cloth Size Prediction`  
**Live URL:** `https://fyp-backend-hi10.onrender.com`  
**Used for:** Live measurement → **Predict** button → `/predict`

### Render setup

| Setting | Value |
|---------|--------|
| Service type | **Web Service** |
| Root directory | `Ai Cloth Size Prediction` (if repo is `pifuhd-main`) |
| Runtime | Python 3 |
| Build command | `pip install -r requirements-render.txt` |
| Start command | `gunicorn app:app --bind 0.0.0.0:$PORT --timeout 120 --workers 1` |

### Must be in Git (same folder)

- `app.py`
- `kameez_model_spec.py`
- `models/final/body_measurement_pipeline.pkl` (trained model, **~30 MB — must be a real git blob, not Git LFS**)
- `requirements-render.txt`

Render does **not** run `git lfs pull` by default. If health shows `model_loaded: false`, check the `.pkl` in GitHub is ~30 MB, not a 133-byte LFS pointer.

### Test after deploy

```text
GET https://fyp-backend-hi10.onrender.com/api/health
→ {"model_loaded": true}
```

### Cold start (free tier)

Render **sleeps after ~15 min idle**. First request can take **30–90 seconds**.

The app now **pings Render in the background** when you open the marketplace or size wizard, so Predict is faster. If you still see “wait ~1 minute”, open the health URL above in a browser tab, wait until it returns `model_loaded: true`, then tap **Predict** again.

**Upgrade to Render paid** ($7/mo) to avoid sleep — recommended for demos/FYP.

---

## 2. 2D try-on — **Render** (live)

**URL:** `https://threed-studio-deploymentt.onrender.com`  
**Used for:** 2D try-on tab → `GET /health`, `POST /api/tryon` (Hugging Face IDM-VTON)

The Flutter app sets:

```text
TRYON_API_BASE=https://threed-studio-deploymentt.onrender.com
```

The shop Vercel site (`fyp-web-code-deployment-flea`) is only the **2D studio UI** — not the try-on API.

### Test

```text
GET https://threed-studio-deploymentt.onrender.com/health
→ {"status":"ok","vton_mode":"real",...}
```

---

## 3. 3D models & reels — **Cloudflare R2** (not Render)

**CDN:** `https://pub-f822ccb86a5c48d6817764a7e50f2c48.r2.dev`

| What | Where in app |
|------|----------------|
| Marketplace 3D kurta/shalwar | `production_urls.dart` → `glbKurtaBlack`, etc. |
| Reel videos | `ProductionUrls.reel1` … `reel5` |
| Chatbot “show black kurta” 3D | `assets/smart-fitao-chat/data/products.json` → R2 URLs |

GLB files are **not** in the Flutter repo or Vercel app deploy — they stream from R2 (fast CDN).

---

## 4. Stripe payments — **Render** (optional)

**Folder:** `strip payment gateway`  
**Example:** `https://smartfitao-stripe-api.onrender.com`

| Build | `pip install -r requirements.txt` |
| Start | `gunicorn smartfitao.wsgi:application --bind 0.0.0.0:$PORT` |

---

## Quick checklist

| Feature | Deploy on | URL |
|---------|-----------|-----|
| Size prediction | **Render** | `fyp-backend-hi10.onrender.com` |
| 2D try-on API | **Render** | `threed-studio-deploymentt.onrender.com` |
| 3D GLB + reels | **R2 CDN** | `pub-f822ccb86a5c48d6817764a7e50f2c48.r2.dev` |
| NLP chatbot | Bundled in app + Vercel `/smart-fitao-chat/` | Same Flutter deploy |
| Stripe | **Render** (optional) | Your stripe service URL |

---

## Flutter / Vercel app env (already in `scripts/vercel-build.sh`)

```text
CLOTH_PREDICT_BASE=https://fyp-backend-hi10.onrender.com
TRYON_API_BASE=https://threed-studio-deploymentt.onrender.com
CLOTH_STUDIO_URL=https://fyp-web-code-deployment-flea.vercel.app/
MEDIA_CDN_BASE=https://pub-f822ccb86a5c48d6817764a7e50f2c48.r2.dev/
STRIPE_PAYMENT_BASE=https://smartfitao-stripe-api.onrender.com
SIZE_API_LOCAL=false
```

After changing any URL, redeploy the Flutter app on Vercel (push to GitHub).
