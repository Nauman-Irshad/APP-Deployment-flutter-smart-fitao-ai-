# Deploy SmartFitao Flutter Web on Vercel

Repo: [APP-Deployment-flutter-smart-fitao-ai-](https://github.com/Nauman-Irshad/APP-Deployment-flutter-smart-fitao-ai-)

## What gets deployed

- Full Flutter app starting at **splash screen** → onboarding → login → 3D marketplace
- Live backends (no localhost):
  - **Size API:** `https://fyp-backend-hi10.onrender.com`
  - **2D try-on + studio:** `https://fyp-web-code-deployment-flea.vercel.app`
  - **3D / reels CDN:** Cloudflare R2
  - **Stripe:** `https://smartfitao-stripe-api.onrender.com`

## Vercel setup (one time)

1. Import this GitHub repo in [Vercel](https://vercel.com/new).
2. Framework preset: **Other** (Vercel reads `vercel.json` automatically).
3. Build command / output directory are already set in `vercel.json`.
4. Deploy — first build installs Flutter (~10–15 min).

## Firebase (required for login & chat)

In [Firebase Console](https://console.firebase.google.com/) → **Authentication** → **Settings** → **Authorized domains**, add:

- `your-project.vercel.app`
- Your custom domain if you add one

## Local production build test

```powershell
cd "E:\fyp whole backend\App"
flutter build web --release `
  --dart-define=CLOTH_PREDICT_BASE=https://fyp-backend-hi10.onrender.com `
  --dart-define=CLOTH_STUDIO_URL=https://fyp-web-code-deployment-flea.vercel.app/ `
  --dart-define=TRYON_API_BASE=https://fyp-web-code-deployment-flea.vercel.app `
  --dart-define=MEDIA_CDN_BASE=https://pub-f822ccb86a5c48d6817764a7e50f2c48.r2.dev/ `
  --dart-define=STRIPE_PAYMENT_BASE=https://smartfitao-stripe-api.onrender.com `
  --dart-define=SIZE_API_LOCAL=false
```

Serve: `npx serve build/web`

## User flow (production web)

1. Splash → onboarding → sign in as customer
2. 3D marketplace → product → **Live measurement** (size prediction)
3. **Continue to 2D Try-On** → upload photo → AI try-on
4. **Find tailor** → Firebase tailor chat + AI chatbot
5. Checkout via Stripe (when Render Stripe API is up)

## Push updates to GitHub

```powershell
git add -A
git commit -m "Deploy: Flutter web on Vercel"
git push deploy main
```

Remote `deploy` points to the deployment repo (see `git remote -v`).
