# Camera work — Computer Vision (`camera_work_computer_vision`)

Flutter-side integration for the **Pose Auto-Capture** stack from:

`E:\fyp whole backend\Computer Vision (Camera Work)`

## What lives here

| Path | Purpose |
|------|---------|
| `camera_cv_config.dart` | `--dart-define=CV_CAMERA_BASE=…` (default `http://127.0.0.1:5000`) |
| `camera_cv_embed.dart` | Conditional export → web iframe (`allow=camera`) or mobile `WebViewWidget` |
| `reference_original_server/` | **Copy** of the Python Flask app (run this; edit the canonical folder in repo root if you prefer a single source of truth) |

## Run the server

From the copied tree or the original backend folder:

```bat
cd "reference_original_server"
set SMARTFITAO_HTTP=1
pip install -r requirements.txt
python app.py
```

Use **HTTP** when testing Flutter Web (Chrome/Edge) so the iframe/WebView can load the page without certificate issues.

## Run Flutter with a custom URL

Android emulator → host loopback:

```bat
flutter run -d chrome --dart-define=CV_CAMERA_BASE=http://127.0.0.1:5000
```

Physical device → your PC LAN IP:

```bat
flutter run --dart-define=CV_CAMERA_BASE=http://192.168.x.x:5000
```

## Flow in the app

**Custom Fitting** → cloth wizard → **Continue to Camera** → loads the Flask `/` page.

- **Web (Edge/Chrome):** Uses an `<iframe allow="camera *; microphone *">` so MediaPipe can request the camera (plain `webview_flutter_web` iframes omit `allow` and block `getUserMedia`).
- **Mobile:** Uses `webview_flutter`.

If the embed shows **connection refused**, Flask is not listening — start `app.py` on port **5000**. Use **Open pose camera in browser** on the Camera step if you prefer the full-tab permission prompt. Wide desktop views inside Flask still show the QR flow; narrow layouts use the camera UI.
