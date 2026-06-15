# Demo accounts (Firebase)

Register each account **once** (or use **Create & login** on the website — account is created automatically), then sign in.

| Role | Email | Password | Display name |
|------|-------|----------|--------------|
| Customer (Ali) | `alismartfitao@gmail.com` | `Ali@12345` | Ali |
| Umer | `umersmartfitao@gmail.com` | `Umer@12345` | Umer |
| Nauman | `naumansmartfitao@gmail.com` | `Nauman@12345` | Nauman |
| Tailor | `tailorahmedsmartfitao@gmail.com` | `Tailor@12345` | Master Tailor Ahmed |
| Seller | `sellerpremiumsmartfitao@gmail.com` | `Seller@12345` | Fashion Store Premium |

## Tailor setup (required for chat + orders)

1. `flutter run -d edge --web-port=65110` (or Order Tracking → Login as Tailor)
2. Register / Demo login as tailor
3. **Add rate** — stitching PKR > 0, mark **available**

## Run apps

| App | Command |
|-----|---------|
| Customer / 3D shop | `flutter run -d edge` |
| 2D try-on | `flutter run -t lib/main_2d_try_on.dart -d edge --web-port=65109` |
| Tailor dashboard | `flutter run -d edge --web-port=65110` → tailor login |
| Seller dashboard | `flutter run -t lib/main_seller_dashboard.dart -d edge` |

## Chat test

1. Customer **Messages**: AI bot + **Master Tailor Ahmed** + **Fashion Store Premium** (real Firestore)
2. 2D try-on → **Find tailor** → chat as **Ali** → tailor **Messages** tab shows **Ali**
3. Tailor replies → customer sees reply in same chat

## Orders & graphs

Place order from **Live measurement** with a marketplace product that has a **sellerId**.

- **Seller dashboard**: product sales + profit (PKR)
- **Tailor dashboard**: stitching earnings from `tailorStitchingTotal`
