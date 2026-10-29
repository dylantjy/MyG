# Setup

Run the backend on your Mac, then run the iOS app in the Simulator. Debug builds of the app talk to `http://localhost:3000`.

## 1. AI model (free, local)

Install [Ollama](https://ollama.com) (or `brew install ollama`), start it, and download the model, about 3.3 GB:

```bash
ollama serve              # skip if the Ollama app is already running
ollama pull gemma3:4b
```

To use OpenAI instead, set `OPENAI_API_KEY` in `backend/.env` (see `.env.example`).

## 2. Backend

**Requirements:** Node.js 18+. With no `MONGODB_URI` set, the backend starts a local MongoDB that keeps its data in `backend/.data/`.

```bash
cd backend
npm install
npm run seed              # optional: demo account demo@myg.app / myg12345 with 3 weeks of workouts
npm start                 # http://localhost:3000
```

The first start downloads a MongoDB binary (about 1 minute). Check it's up with `curl localhost:3000`. The startup log shows which AI model and endpoint it is using.

To use MongoDB Atlas instead, set `MONGODB_URI` in `backend/.env`.

## 3. iOS app

**Requirements:** a Mac with Xcode 16+. The project targets iOS 18.4.

### In Xcode
Open `ios/MyG.xcodeproj`, pick an iPhone simulator, and press **Run**. Simulator builds don't need signing. To run on a physical iPhone, set your Apple ID as the Team under **Signing & Capabilities**, change the Bundle Identifier, and point `ios/MyG/APIConfig.swift` at your Mac's LAN IP.

### From the terminal
```bash
xcodebuild -project ios/MyG.xcodeproj -scheme MyG -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath build build
xcrun simctl boot "iPhone 16"; open -a Simulator
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/MyG.app
xcrun simctl launch --console booted com.aldy.MyG
```

Use a simulator name from `xcrun simctl list devices available`. If your Xcode is older than 16.3, add `IPHONEOS_DEPLOYMENT_TARGET=18.0` before the final `build`.

## Tests

```bash
cd backend && npm test    # Jest + Supertest with an in-memory MongoDB; OpenAI is mocked
```
