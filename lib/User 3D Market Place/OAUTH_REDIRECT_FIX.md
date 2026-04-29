# OAuth redirect URL not opening (127.0.0.1:65106)

## Why it happens

After sign-in (e.g. Google/Firebase), the browser is redirected to:

`http://127.0.0.1:65106/?code=...&state=...`

That URL only works if your app is **actually running on port 65106**. If the app is on another port (e.g. 54970), nothing is listening on 65106, so the page does not open.

## Fix

### 1. Run the app on port 65106

So that the redirect lands on your running app:

**From terminal:**
```bash
flutter run -t lib/main_marketplace.dart -d edge --web-port=65106
```

Or in Cursor/VS Code: use the launch config **"3D Marketplace (Web, port 65106 for OAuth)"** so the app runs on 65106.

### 2. Firebase / Google Cloud settings

- **Firebase Console** → Authentication → Settings → **Authorized domains**  
  Add `127.0.0.1` if it is not there.

- If you use **Google Sign-In**: in **Google Cloud Console** → APIs & Services → Credentials → your OAuth 2.0 Client (Web client) → **Authorized redirect URIs**  
  Add: `http://127.0.0.1:65106/`  
  (Use the same port you use when running the app.)

After that, open the app at `http://127.0.0.1:65106`, sign in again; the callback URL should open and complete the flow.
