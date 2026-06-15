# AI Chat Bot — Phone / APK (main setup)

## Phone par kaise chalega (recommended)

**Do NOT** use `STUDIO_LOCAL_DEV=true` on a real phone — that is for PC/Edge only.

1. Phone par **internet** on (Wi‑Fi / mobile data).
2. Build or run **without** local flags:

```bash
cd App
flutter run -d android
```

3. App → **Messages** → **AI Chat Bot**
4. Try: `Show me black kurta` → NLP answer + **3D model**

### APK install on phone

```bash
flutter build apk --release
```

APK: `build/app/outputs/flutter-apk/app-release.apk`  
Copy to phone and install.

- **NLP + FAQ** → bundled inside APK (`assets/smart-fitao-chat/`)
- **3D GLB models** → download from Vercel when online

---

## VS Code

Use: **SmartFitao Phone — AI chat in APK (Android)**

---

## PC / Edge (optional — not for phone)

```bash
flutter run -d edge --dart-define=STUDIO_LOCAL_DEV=true
```

Requires `.\scripts\start-local-website-for-app.ps1` on PC.

---

## Files

| File | Role |
|------|------|
| `assets/smart-fitao-chat/` | NLP UI + FAQ in APK |
| `ai_chatbot_mobile.dart` | Phone WebView + bundled chat |
| `ai_chatbot_web.dart` | Edge only (iframe) |
| `studio_config.dart` | `useBundledChatInApp` |

Update bundled chat after website changes: copy from  
`_gh_push/Figma Design for Frontend/public/smart-fitao-chat/` → `App/assets/smart-fitao-chat/`
