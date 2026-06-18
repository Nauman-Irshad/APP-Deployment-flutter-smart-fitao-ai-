# SmartFitao — Feature status (yes / no)

Last updated: 2026-06-06. Test on your target device (web vs Android) — some items differ by platform.

| Feature | Customer | Tailor | Seller | Status | Notes |
|--------|----------|--------|--------|--------|-------|
| Login / logout (orders kept) | Yes | Yes | Yes | **Yes** | Logout no longer wipes all prefs |
| Back button → previous screen | Yes | Yes | Yes | **Mostly** | Marketplace logout uses pop; some auth OTP screens may still reset stack |
| 3D marketplace browse | Yes | — | — | **Yes** | Bundled + Firestore seller products |
| Product upload (seller) | — | — | Yes | **Yes** | Active products show on 3D marketplace |
| Seller products list | — | — | Yes | **Yes** | Shows 2 bundled marketplace items + upload status; Firestore uploads below |
| Reels playback | Yes | — | — | **Yes** | Fixed: uses working R2 desktop URLs (not broken mobile/720p) |
| Reels — all videos button | Yes | — | — | **Yes** | “All videos” on Reel tab |
| Reels — tailor upload | — | Yes | — | **Yes** | Add video in nav; new reel first + snackbar + Home/Reel badge |
| Order tracking (6 steps custom) | Yes | Yes | Yes | **Yes** | Horizontal scroll + scrollbar; swipe hint on card |
| Order tracking — more details | Yes | Yes | Yes | **Yes** | Horizontal scroll so buttons not clipped on narrow phones |
| Tailor ↔ customer chat | Yes | Yes | — | **Yes** | Firebase; tailor Messages tab + badge |
| Seller ↔ customer chat | Yes | — | Yes | **Yes** | Seller Chat tab + badge |
| Customer Chat tab red badge | Yes | — | — | **Yes** | Unread from tailor or seller |
| AI NLP chatbot | Yes | — | — | **Needs local server** | Run `App\scripts\start-local-website-for-app.ps1` + `STUDIO_LOCAL_DEV=true` |
| Stripe / demo checkout | Yes | — | — | **Yes** | Demo flow uses Firebase uid |
| 2D try-on | Yes | — | — | **Yes** | Separate tab |
| Tailor earnings (stitch + PKR 500) | — | Yes | — | **Yes** | Per confirmed tailor payment |
| Seller profit after confirm payment | — | — | Yes | **Yes** | Only when `sellerPaymentReleasedAt` set |
| Removed “Find Your Perfect Tailor” banner | Yes | — | — | **Yes** | Removed from marketplace landing |
| Removed “Become a Seller” promo (user) | Yes | — | — | **Yes** | Landing + profile seller card removed |
| Tailor profile image `assets/4.png` 404 | — | Yes | — | **Fixed** | Now `assets/4.webp` |

## How to run NLP chat locally

```powershell
cd "E:\fyp whole backend\App\scripts"
.\start-local-website-for-app.ps1
```

In another terminal:

```powershell
cd "E:\fyp whole backend\App"
flutter run --dart-define=STUDIO_LOCAL_DEV=true
```

Phone on same Wi‑Fi: add `--dart-define=LOCAL_DEV_HOST=YOUR_PC_IP`.

## Firebase Storage (seller 3D + tailor reels)

Uploads on **deployed** app go to Firebase Storage (not localhost). In Firebase Console → Storage → Rules, allow authenticated seller/tailor writes and public reads for:

- `seller-products/{sellerId}/**`
- `marketplace-reels/{tailorId}/**`

## Demo accounts

- Customer: `alismartfitao@gmail.com` / `Ali@12345`
- Tailor: `tailorahmedsmartfitao@gmail.com` / `Tailor@12345`
- Seller: `sellerpremiumsmartfitao@gmail.com` / `Seller@12345`
