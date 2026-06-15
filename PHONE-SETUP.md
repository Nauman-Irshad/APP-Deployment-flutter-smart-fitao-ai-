# SmartFitao — real phone (Size → Camera → Try-on → Chat)

PC runs all Flask/API servers. The phone app talks to your **PC Wi‑Fi IP**, not `127.0.0.1`.

## Quick start

1. Phone and PC on the **same Wi‑Fi**.
2. USB debugging ON (Android).
3. In PowerShell:

```powershell
cd "E:\fyp whole backend\App"
.\RUN-PHONE-APP.ps1 -RunOnPhone
```

Optional: skip Stripe while testing:

```powershell
.\RUN-PHONE-APP.ps1 -RunOnPhone -SkipStripe
```

## What runs on the PC

| Service | Port | Phone URL |
|---------|------|-----------|
| Size prediction Flask | 5001 | `http://PC_IP:5001` |
| CV camera / landmarks | 5003 | `http://PC_IP:5003` |
| 2D try-on API | 8765 | `http://PC_IP:8765` |
| 3D product upload | 5190 | `http://PC_IP:5190` |
| Stripe (optional) | 8000 | `http://PC_IP:8000` |

Find **PC_IP**: `ipconfig` → IPv4 on Wi‑Fi (e.g. `192.168.1.5`).

## Test before Flutter

On the phone browser open:

- `http://PC_IP:5001/` — should load size API / health
- `http://PC_IP:5003/` — camera server

If these fail, fix **Windows Firewall** (allow inbound on Private network for ports above) or temporarily allow Python/Node through the firewall.

## Flutter defines (one flag)

`RUN-PHONE-APP.ps1` sets:

- `LOCAL_DEV_HOST=PC_IP` → size, camera, try-on, stripe
- `CLOTH_PREDICT_BASE`, `CV_CAMERA_BASE`, `TRYON_API_BASE`, etc.

Manual run:

```powershell
cd "E:\fyp whole backend\App"
$ip = "192.168.1.5"   # your PC
flutter run -d android `
  --dart-define=LOCAL_DEV_HOST=$ip `
  --dart-define=CLOTH_PREDICT_BASE=http://${ip}:5001 `
  --dart-define=CV_CAMERA_BASE=http://${ip}:5003 `
  --dart-define=TRYON_API_BASE=http://${ip}:8765 `
  --dart-define=LOCAL_PRODUCT_API_BASE=http://${ip}:5190
```

## Chat bot on phone

- **Default (recommended):** NLP chat is **bundled in the APK**; 3D assets load from Vercel when online. No PC chat server needed.
- **Dev only:** `.\RUN-PHONE-APP.ps1 -WithLocalChat -RunOnPhone` starts Vite `:5177` and enables `STUDIO_LOCAL_DEV` + `LOCAL_DEV_HOST`.

## Emulator vs real phone

| Device | `LOCAL_DEV_HOST` |
|--------|------------------|
| Real phone on Wi‑Fi | Required (`192.168.x.x`) |
| Android emulator | Optional; size uses `10.0.2.2` if omitted |

## Full flow checklist

1. `.\RUN-ALL-BACKEND-SERVICES.ps1` (or `RUN-PHONE-APP.ps1` which calls it)
2. Wait until health URLs respond on PC
3. `flutter run -d android` with `LOCAL_DEV_HOST`
4. In app: Size prediction → Camera landmarks → 2D try-on → Chat

Stripe on phone needs the same `PC_IP:8000` and a stable connection to `api.stripe.com` (VPN if blocked in your region).
