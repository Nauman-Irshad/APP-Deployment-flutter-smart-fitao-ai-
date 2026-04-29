# Fyp-SmartFitaoAi-ft-OrderTracking

Flutter app for Smart Fitao AI: 3D marketplace with `model_viewer_plus`, Firebase Auth + Firestore (orders pipeline user → seller), tailor & seller dashboards, NLP chatbot, size charts, checkout, and reels.

## Getting started

```bash
flutter pub get
flutter run -d chrome
```

This project is a Flutter application. See [Flutter documentation](https://docs.flutter.dev/) for setup.

---

## Complete file structure (high level)

Smart-Fitao-ai_app-main/

- `analysis_options.yaml`, `devtools_options.yaml`, `pubspec.yaml`, `pubspec.lock`
- `firestore.indexes.json` — Firestore composite index: `orders` (`status` + `createdAt`)
- `APP_STRUCTURE.md` — older structure notes
- `.vscode/launch.json` — VS Code launch config
- `assets/` — images, banners, reels, videos (declared in pubspec)
- `3d viewer work/models/` — GLTF/GLB source models (also under `web/models/`)
- `lib/` — Dart source
  - `main.dart` — Firebase init + `AppRoot`
  - `main_marketplace.dart`, `main_standard_size.dart` — alternate entrypoints
  - `firebase_options.dart` — primary Firebase config (`websmart-702de`)
  - `app/` — `MaterialApp`, routes
  - `core/` — constants, theme, utils, widgets
  - `data/` — models + services (e.g. `seller_service` → Firestore `orders`)
  - `seller_dashboard/` — seller UI + orders
  - `Tailor/` — tailor UI
  - `Order-Tracking-System/` — order tracking module
  - `User 3D Market Place/` — marketplace, auth, checkout, reels
- `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` — platform runners
- `test/widget_test.dart`

Not committed (see `.gitignore`): `build/`, `.dart_tool/`, local logs.
