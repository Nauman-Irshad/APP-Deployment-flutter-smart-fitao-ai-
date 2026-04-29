# Smart Fitao AI – App File Structure

Root: `smart fitao ai edit 9 zip/`

---

## Project root

```
smart fitao ai edit 9 zip/
├── .gitignore
├── .metadata
├── analysis_options.yaml
├── pubspec.yaml
├── README.md
├── untitled1.iml
├── 3d viewer work/          # 3D mesh assets (single source for models)
├── android/                # Android platform
├── assets/                 # Images, banners, reels, videos
├── ios/                    # iOS platform
├── lib/                    # Dart source code
├── linux/                  # Linux desktop (if present)
├── macos/                  # macOS desktop (if present)
├── test/                   # Unit/widget tests
├── web/                    # Web platform + served 3D models
└── windows/                # Windows desktop (if present)
```

---

## lib/ (Dart source)

```
lib/
├── firebase_options.dart
├── main.dart                     # App entry → runApp(AppRoot)
│
├── app/                          # App shell & routing
│   ├── app.dart                  # MaterialApp, theme, routes
│   └── routes.dart               # Named routes (splash, auth, marketplace, etc.)
│
├── core/                         # Shared constants, theme, utils, widgets
│   ├── constants/
│   │   ├── app_strings.dart
│   │   ├── asset_paths.dart
│   │   ├── auth_types.dart       # UserType, AuthScreen enums
│   │   └── route_names.dart
│   ├── themes/
│   │   └── app_theme.dart
│   ├── utils/
│   │   ├── auth_storage.dart
│   │   └── connectivity_check.dart
│   └── widgets/
│       ├── anim/
│       │   ├── circle_anim_bg.dart
│       │   └── tracking_anim_bg.dart
│       └── loading_widget.dart
│
├── data/                         # Data layer
│   ├── models/                   # Stubs: user, product, order, measurement, reel
│   └── services/
│       ├── firebase_service.dart
│       ├── order_tracking_service.dart
│       ├── user_app_order.dart
│       └── seller_service.dart
│
├── legacy/                       # Temporary / debug
│   └── debug_orders.dart
│
├── login_database/               # (folder; contents may vary)
│
├── seller_dashboard/
│   ├── bottom_navi.dart
│   ├── income.dart
│   ├── messages.dart
│   ├── orders_page.dart
│   ├── product.dart
│   ├── profile.dart
│   ├── seller_center.dart
│   ├── seller_service.dart
│   └── tools.dart
│
├── Tailor/
│   ├── botm_navi.dart
│   ├── tailor_center.dart
│   ├── tools.dart
│   ├── t_income.dart
│   ├── t_messages.dart
│   ├── t_product.dart
│   └── t_profile.dart
│
└── User 3D Market Place/
    ├── 3d_marketplace.dart       # Home: 3D product grid
    ├── chat.dart
    ├── create_new_password.dart
    ├── firebase_options.dart
    ├── futuristic_onboarding.dart
    ├── main.dart
    ├── next_screen.dart
    ├── onboarding_screen.dart
    ├── product_opener.dart
    ├── product_viewer.dart       # Product detail + 3D viewer
    ├── profile.dart
    ├── reel.dart
    ├── ship_to_tailor.dart
    ├── size_predictor.dart
    ├── standard_sizes.dart
    ├── tailors.dart
    ├── tailor_delivered.dart
    ├── tailor_portfolio.dart
    ├── tailor_to_ship.dart
    ├── to_pay.dart
    ├── to_receive.dart
    ├── to_review_button.dart
    ├── user_profile_screen.dart
    │
    ├── anim/
    │   ├── circle_anim_bg.dart
    │   └── tracking_anim_bg.dart
    │
    ├── database/                 # Re-exports from lib/data/services & core/utils & legacy
    │   ├── checkout_page.dart
    │   ├── connectivity_check.dart  → core/utils
    │   ├── debug_orders.dart        → legacy
    │   ├── firebase_service.dart    → data/services
    │   ├── order_tracking_service.dart → data/services
    │   ├── postgres_schema.sql
    │   └── user_app_order.dart      → data/services
    │
    ├── loginforgetsign/          # Splash → Login → Auth flow (uses core/constants/auth_types)
    │   ├── auth_flow.dart
    │   ├── auth_storage.dart     → core/utils
    │   ├── forget_password.dart
    │   ├── forgot_password.dart
    │   ├── login_form.dart
    │   ├── login_seller.dart
    │   ├── login_tailor.dart
    │   ├── login_user.dart
    │   ├── otp_verification.dart
    │   ├── register.dart
    │   ├── register_form.dart
    │   ├── select_login.dart
    │   ├── splash_screen.dart
    │   └── ultra_splash_screen.dart
    │
    ├── model 1 ai size prediction/
    │   └── live_measurement.dart
    │
    └── reels_videos/              # Video files under lib (if any)
        └── *.mp4
```

---

## 3d viewer work/ (3D models – source for app)

```
3d viewer work/
└── models/
    ├── product1/
    │   ├── baseColor.png
    │   ├── buffer.bin
    │   └── sample1.gltf
    ├── product2/
    │   ├── baseColor.png
    │   ├── buffer.bin
    │   └── sample1.gltf
    ├── product3/
    │   ├── sample5.bin
    │   └── sample5.gltf
    ├── product4/
    │   ├── sample8.bin
    │   └── sample8.gltf
    └── product5/
        ├── sample4.bin
        └── sample4.gltf
```

---

## assets/

```
assets/
├── 1.webp … 6.webp
├── abdul rahman.jpg
├── banner 1.png, banner 2.png, banner 33.png
├── Frame 9.png
├── profile.jpg
├── tailor 4 .jpg, tailor.png, tailor2.png, tailro 3.png
├── reels_videos/
│   └── *.mp4
└── videos/
    ├── tailor1.mp4
    └── tailor2.mp4
```

---

## web/

```
web/
├── index.html
├── manifest.json
├── favicon.png
├── icons/
│   ├── Icon-192.png
│   ├── Icon-512.png
│   ├── Icon-maskable-192.png
│   └── Icon-maskable-512.png
└── models/                    # Copy of 3d viewer work/models for web
    ├── product1/ (sample1.gltf + buffer.bin + baseColor.png)
    ├── product2/ …
    ├── product3/ …
    ├── product4/ …
    └── product5/ …
```

---

## android/

```
android/
├── .gitignore
├── build.gradle.kts
├── gradle.properties
├── gradlew, gradlew.bat
├── settings.gradle.kts
├── app/
│   ├── build.gradle.kts
│   ├── google-services.json
│   └── src/
│       ├── debug/AndroidManifest.xml
│       ├── main/
│       │   ├── AndroidManifest.xml
│       │   ├── kotlin/.../MainActivity.kt
│       │   ├── java/.../GeneratedPluginRegistrant.java
│       │   └── res/ (drawable, mipmap, values)
│       └── profile/AndroidManifest.xml
└── gradle/wrapper/
```

---

## ios/

- Standard Flutter `ios/` project (Runner, Podfile, etc.).

---

## test/

- Flutter default `test/` folder for unit and widget tests.

---

## Flow summary

- **Entry:** `lib/main.dart` → `AppRoot` (from `lib/app/app.dart`). Theme from `core/themes/app_theme.dart`.
- **Routes:** `app/routes.dart` defines named routes; `AppRoot` uses `onGenerateRoute`.
- **Initial route:** `UltraSplashScreen` (from `User 3D Market Place/loginforgetsign/`).
- **Splash:** `ultra_splash_screen.dart` → `futuristic_onboarding.dart`.
- **Onboarding:** “Get Started” → `AuthFlow()` (loginforgetsign; uses `core/constants/auth_types.dart`).
- **Auth:** `auth_flow.dart` → `select_login.dart` → login/register/forgot in `loginforgetsign/`.
- **After login:** Navigation to `MarketPlace3D`, Tailor (`Tailor/botm_navi`), or Seller (`seller_dashboard/bottom_navi`) by role.
- **3D models:** `3d viewer work/models/`; for web, `web/models/`.
- **Services:** Firebase, order tracking, user orders, seller stats live in `lib/data/services/`; auth storage and connectivity in `lib/core/utils/`.
