# Cloudflare par reels (video) + 3D (GLB) upload — app ko links dena

**Best option:** Cloudflare **R2** (storage) + public URL ya apna domain.  
App mein links: `assets/remote_media_urls.json` (har file ka full `https://` link).

---

## Part 1 — Cloudflare R2 bucket (free tier se start)

1. Login: https://dash.cloudflare.com/
2. Left menu → **R2 Object Storage** → **Create bucket**
   - Name: `smartfitao-media` (jo marzi)
3. Bucket kholo → **Settings**
4. **Public access** enable karo (ya **Custom domain** connect karo, e.g. `cdn.smartfitao.com`)

### Files upload (dashboard se — sabse aasaan)

1. Bucket → **Upload**
2. Folders banao:
   - `reels/` → saari `.mp4` yahan
   - `models/kurta/` → `.glb` files
3. Har file par click → **Copy URL** / public link

Public URL examples:

```text
https://pub-xxxxxxxx.r2.dev/reels/6767035-uhd_2160_3840_25fps.mp4
https://pub-xxxxxxxx.r2.dev/models/kurta/black%20kurta%20.glb
```

(Custom domain ho to: `https://cdn.yourdomain.com/reels/...`)

---

## Part 2 — Links app mein paste karo

File: `App/assets/remote_media_urls.json`

Har **khali** `""` ki jagah apna **poora https link** paste karo:

```json
{
  "reelsByFileName": {
    "6767035-uhd_2160_3840_25fps.mp4": "https://pub-xxx.r2.dev/reels/6767035-uhd_2160_3840_25fps.mp4",
    "11907197_2160_3840_25fps.mp4": "https://pub-xxx.r2.dev/reels/11907197_2160_3840_25fps.mp4"
  },
  "modelsByPath": {
    "landing page product/kurta/black kurta .glb": "https://pub-xxx.r2.dev/models/kurta/black%20kurta%20.glb"
  }
}
```

**Zaroori:** Reel file names **exact** wahi hon jo app mein hain (see `lib/User 3D Market Place/reel_media.dart`).

3D paths **exact** wahi hon jo `landing_page_products.dart` mein `modelPath` hai.

---

## Part 3 — APK dubara build

```powershell
cd "E:\fyp whole backend\App"
.\RUN-BUILD-APK-LIVE.ps1
```

Nayi APK phone par install → **internet ON** → reels + 3D Cloudflare se load hongi.

---

## Option B — Sab files ek base URL ke neeche (folder same structure)

Agar R2 par paths ye rakho:

```text
reels_videos/FILE.mp4
landing page product/kurta/black kurta .glb
```

Build with base URL:

```powershell
flutter build apk --release `
  --dart-define=MEDIA_CDN_BASE=https://pub-xxxxxxxx.r2.dev/ `
  --dart-define=CLOTH_PREDICT_BASE=https://fyp-backend-hi10.onrender.com `
  ...
```

Ya `RUN-BUILD-APK-LIVE.ps1` mein `-MediaCdnBase` add kar sakte ho (agar script updated ho).

JSON mein khali chhor sakte ho — app `MEDIA_CDN_BASE + path` banayegi.

---

## Video ke liye Cloudflare Stream? (optional)

Bari traffic / adaptive streaming chahiye ho to **Stream** use karo; har video ka **HLS URL** `reelsByFileName` mein paste karo.  
FYP demo ke liye **R2 + direct .mp4** kaafi hai.

---

## Google Drive (not recommended)

Drive links video player / 3D viewer mein aksar **break** hoti hain. Cloudflare R2 behtar hai.

---

## Test link browser se

Phone se pehle Chrome mein GLB ya MP4 URL kholo — download/play hona chahiye.  
Phir APK test karo.

---

## Reel file names (copy checklist)

| File name |
|-----------|
| `6767035-uhd_2160_3840_25fps.mp4` |
| `11907197_2160_3840_25fps.mp4` |
| `7146667-uhd_2160_3840_24fps.mp4` |
| `11907055_2160_3840_25fps.mp4` |
| `4622040-uhd_2160_4096_25fps.mp4` |

Source on PC: `App/assets/reels_videos/` or `App/lib/User 3D Market Place/reels_videos/`
