# Setup

## iOS app

**Requirements:** a Mac with Xcode 16+ and a free Apple ID. The project targets iOS 18.4.

1. Open `ios/MyG.xcodeproj` in Xcode. Swift Package Manager fetches the GoogleSignIn dependency automatically.
2. Select the **MyG** target → **Signing & Capabilities**, choose your Apple ID as the Team, and change the Bundle Identifier to something unique (e.g. `com.yourname.MyG`).
3. Pick a simulator (or a connected iPhone) and press **Run**.

The app uses the deployed backend at `https://myg-de3i.onrender.com`. To use your own, change `baseURL` in `ios/MyG/APIConfig.swift`.

> The backend is on Render's free tier. If the first request fails or hangs, wait 30–60 seconds for it to wake up and try again.

## Backend

**Requirements:** Node.js 18+, a MongoDB Atlas cluster, an OpenAI API key, and a Google Cloud Vision service account (food scanner only).

```bash
cd backend
npm install
cp .env.example .env   # then fill in your values
npm start              # http://localhost:3000
npm test               # Jest + Supertest with an in-memory MongoDB
```
