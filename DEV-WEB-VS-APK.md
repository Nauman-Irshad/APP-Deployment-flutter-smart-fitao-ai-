# Web (Edge) vs Phone (APK) — alag kaise rakhein

## Masla kya hai?

`App/lib/` **ek hi codebase** hai:

| Aap kya karte ho | Kya change hota hai |
|------------------|---------------------|
| Edge par `flutter run` + code edit / hot reload | Sirf **browser** (65106) |
| `RUN-BUILD-APK-LIVE.ps1` + naya APK install | **Phone** par naya app |
| `Computer Vision` / `id-2d-try-on` local edit | Sirf jab app **local URL** use kare (Edge dev) |

**Purana APK phone par tab tak same rehta hai** jab tak aap dubara build + install na karein.

Web par jo change **dikhta** hai wo phone par tab aata hai jab:

1. Aap `lib/` (Flutter) edit karte ho **aur**
2. Phir `RUN-BUILD-APK-LIVE.ps1` chala kar **naya APK** install karte ho

Sirf Edge par test karna = phone ko chhedna nahi.

---

## Web develop (phone ko mat chhedo)

```powershell
cd "E:\fyp whole backend\App"
.\RUN-EDGE-LOCAL-BACKEND.ps1    # optional: local APIs
.\RUN-EDGE-MARKETPLACE.ps1      # Edge http://127.0.0.1:65106
```

- Local: Size `:5001`, Camera `:5003`, 2D API `:8765`
- **APK is script se build nahi hota**

---

## Phone / FYP demo APK (live URLs)

```powershell
.\RUN-BUILD-APK-LIVE.ps1
# install: build\app\outputs\flutter-apk\app-release.apk
```

- Render, Vercel, R2 — **localhost nahi**
- Jab tak ye script na chalao, phone par purana APK same rahega

---

## Kaun si files kis ko affect karti hain

| Folder / file | Edge localhost | APK (LIVE build) |
|---------------|----------------|------------------|
| `App/lib/**` | Haan (reload/build web) | Haan **jab naya APK build** |
| `Computer Vision (Camera Work)/` | Haan (`:5003`) | Nahi (APK → Vercel CV) |
| `id-2d-try-on/` local `:8765` | Haan | Nahi (APK → Vercel shop API) |
| Vercel / Render deploy | Nahi (local dev) | Haan (APK URLs) |

---

## Short rules

1. **Roz marra web test** → `RUN-EDGE-MARKETPLACE.ps1` only  
2. **Phone update chahiye** → tab hi `RUN-BUILD-APK-LIVE.ps1`  
3. **APK stable rakhni hai** → web par jitna marzi edit; phone par purana APK chalao jab tak naya build na ho
