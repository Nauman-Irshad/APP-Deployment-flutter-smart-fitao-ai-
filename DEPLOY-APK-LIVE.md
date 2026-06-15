# Phone APK — sab kuch LIVE (PC server band, sirf internet)

Jab tum **release APK** phone par install karo, app **deployed** servers use karti hai — laptop par Flask chalane ki zaroorat nahi.

---

## Step 1 — Pehle ye live hon (ek dafa setup)

| Service | Kahan | Status |
|---------|--------|--------|
| Size `/predict` | https://fyp-backend-hi10.onrender.com | Usually already live |
| Shop + 2D try-on | https://fyp-web-code-deployment-flea.vercel.app | Website deploy = same |
| 3D models + catalog | Same Vercel URL | `DEPLOY_MEDIA_TO_VERCEL.md` |
| Camera / landmarks | Vercel CV URL (APK mein baked) | Same as website phone scan |
| Chat NLP | APK ke andar | Internet sirf 3D ke liye |
| Stripe Pay | **Tumhe deploy karna hai** | See Step 2 |

**Website update:** `website +dashboard front deployed` → `git push` → Vercel.

**Size API update:** `pifuhd-main\Ai Cloth Size Prediction` → GitHub → Render service `fyp-backend-hi10` redeploy.

---

## Step 2 — Stripe live (payment ke liye)

Abhi Stripe sirf laptop `:8000` par hai. Phone APK ke liye:

1. [Render](https://render.com) → **New Web Service**
2. Repo/folder: `strip payment gateway`
3. **Build:** `pip install -r requirements.txt`
4. **Start:** `gunicorn smartfitao.wsgi:application --bind 0.0.0.0:$PORT`
5. Env: `ALLOWED_HOSTS=.onrender.com`, Stripe keys (settings.py ya env)
6. Copy URL: `https://smartfitao-stripe-xxxx.onrender.com`

Test: `https://YOUR-URL/api/create-checkout-session/` (POST from app)

---

## Step 3 — APK build (sab live URLs andar)

```powershell
cd "E:\fyp whole backend\App"
.\RUN-BUILD-APK-LIVE.ps1
```

Stripe deploy ke baad:

```powershell
.\RUN-BUILD-APK-LIVE.ps1 -StripeBase "https://YOUR-STRIPE.onrender.com"
```

APK file:

`build\app\outputs\flutter-apk\app-release.apk`

Phone par copy karke install karo.

---

## Step 4 — Phone par test

1. **Wi‑Fi / mobile data ON**
2. Install APK
3. Flow try karo:
   - Size prediction → Render
   - Camera → Vercel CV
   - 2D try-on → Vercel `/api/tryon`
   - Chat → bundled; 3D online
   - Pay → sirf jab `-StripeBase` diya ho build mein

**Mat karo:** `STUDIO_LOCAL_DEV`, `LOCAL_DEV_HOST` — ye sirf PC dev ke liye hain.

---

## Kya PC par chalana zaroori nahi

| Module | Phone APK |
|--------|-----------|
| Flask 5001, 5003, 8765 | ❌ Not needed |
| `RUN-PHONE-APP.ps1` | ❌ Not needed |
| Internet | ✅ Required |
| Firebase | ✅ Same project (already cloud) |

---

## Agar kuch fail ho

| Problem | Fix |
|---------|-----|
| Size error | Render sleep — pehli request 30–60s wait; check `/api/health` |
| 2D try-on slow/fail | Vercel HF quota; internet check |
| Camera blank | CV Vercel URL browser mein kholo; camera permission |
| 3D nahi dikhta | Vercel par GLB sync + redeploy |
| Pay error | Stripe Render URL build mein `-StripeBase` do; VPN agar Stripe API slow |

---

## URLs ek jagah (`lib/config/production_urls.dart`)

Shop, Render size, CV Vercel — yahan change karo agar naya domain ho, phir dubara `.\RUN-BUILD-APK-LIVE.ps1`.
