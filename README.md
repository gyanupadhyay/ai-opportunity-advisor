# AI Opportunity Advisor (Pathora AI)

An AI-powered chatbot that helps students discover scholarships, internships, fellowships, exchange programs, and global opportunities through a conversational interface with smart quick-reply suggestions.

**Tech Stack:** Jaspr (Dart) frontend, Express.js backend, Groq AI (Llama 3.3 70B), Firebase Firestore, Web Speech API for voice input.

---

## Architecture

```
User  →  Jaspr Web App (Firebase Hosting)  →  Express API (Render)  →  Groq AI + Firestore  →  Response
```

| Layer | Technology | Hosting |
|-------|-----------|---------|
| Frontend | Jaspr (Dart → JS) | Firebase Hosting (free Spark plan) |
| Backend | Express.js + TypeScript | Render (free tier) |
| AI Model | Groq — Llama 3.3 70B Versatile | Groq API (free tier) |
| Database | Cloud Firestore | Firebase (free Spark plan) |

---

## Features

- **Conversational onboarding** — the AI asks about your country, education level, field of study, and interests
- **Quick reply chips** — clickable options appear for common questions (education level, field, region, etc.)
- **Opportunity matching** — recommends scholarships, internships, fellowships, and more from Firestore
- **Voice input** — click the mic button to speak your answer (Chrome, Edge, Safari)
- **Responsive UI** — fluid scaling with `clamp()`, `dvh`, and `min()` for all screen sizes

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| **Dart SDK** | >= 3.10 | https://dart.dev/get-dart |
| **Node.js** | 18+ | https://nodejs.org/ |
| **Firebase CLI** | latest | `npm install -g firebase-tools` |
| **Jaspr CLI** | latest | `dart pub global activate jaspr_cli` |

---

## Project Structure

```
ai-opportunity-advisor/
├── frontend/                   # Jaspr web app (Dart)
│   ├── lib/
│   │   ├── components/
│   │   │   ├── chat_widget.dart       # Main chat UI, message list, quick replies
│   │   │   ├── chat_input_bar.dart    # Text input + mic + send (isolated state)
│   │   │   ├── message_bubble.dart    # Single message renderer
│   │   │   └── opportunity_card.dart  # Opportunity card in chat
│   │   ├── pages/
│   │   │   ├── home_page.dart         # Landing page
│   │   │   └── chat_page.dart         # Chat page wrapper
│   │   ├── models/                    # message, opportunity
│   │   ├── services/
│   │   │   ├── api_service.dart       # HTTP calls to backend
│   │   │   └── speech_service.dart    # Web Speech API wrapper
│   │   ├── app.dart                   # Router setup
│   │   └── main.client.dart
│   ├── web/
│   │   ├── index.html
│   │   └── styles.css                 # All styles (responsive, clamp, dvh)
│   └── pubspec.yaml
├── server/                     # Express.js backend (for Render deployment)
│   ├── src/
│   │   ├── index.ts                   # Express app, routes, /health endpoint
│   │   ├── chat_handler.ts            # POST /handleChatMessage handler
│   │   ├── firebase.ts                # Firebase Admin SDK init
│   │   ├── recommendation_engine.ts   # Firestore opportunity matching
│   │   ├── services/
│   │   │   └── ai_service.ts          # Groq API integration
│   │   └── models/
│   │       └── user_model.ts          # User profile types
│   ├── package.json
│   ├── tsconfig.json
│   └── .env.example
├── functions/                  # Firebase Cloud Functions (alternative backend)
│   ├── src/
│   │   └── ...                        # Same logic as server/, for Firebase deploy
│   ├── package.json
│   └── .env.example
├── firebase.json               # Firebase Hosting + Firestore config
├── firestore.rules             # Security rules
├── firestore.indexes.json      # Composite indexes
├── seed_firestore.js           # Sample opportunity data seeder
├── .firebaserc                 # Firebase project alias
└── .gitignore
```

---

## Setup & Run Locally

### 1. Clone and Install

```bash
cd ai-opportunity-advisor

# Install frontend dependencies
cd frontend && dart pub get && cd ..

# Install backend dependencies
cd server && npm install && cd ..
```

### 2. Configure Environment

```bash
# Copy the example env file
cp server/.env.example server/.env
```

Edit `server/.env` and set:

```
GROQ_API_KEY=gsk_your-groq-api-key-here
PORT=8080
FIREBASE_SERVICE_ACCOUNT={"type":"service_account",...}
```

- **Groq API key** — get one free at https://console.groq.com
- **Firebase service account** — download from Firebase Console > Project Settings > Service Accounts > Generate new private key, then paste the entire JSON as a single line

### 3. Seed Firestore with Sample Data

```bash
# Install firebase-admin at root (if not already)
npm install firebase-admin

# Set environment for emulator or production
# For production Firestore:
node seed_firestore.js

# For local emulator:
# set FIRESTORE_EMULATOR_HOST=127.0.0.1:8081  (PowerShell: $env:FIRESTORE_EMULATOR_HOST = "127.0.0.1:8081")
# set GCLOUD_PROJECT=demo-opportunity-advisor   (PowerShell: $env:GCLOUD_PROJECT = "demo-opportunity-advisor")
# node seed_firestore.js
```

### 4. Start the Backend

```bash
cd server
npm run build && npm start
```

The API will be available at `http://localhost:8080`. Test with:
```bash
curl http://localhost:8080/health
```

### 5. Start the Frontend

```bash
cd frontend
jaspr serve --dart-define=API_BASE_URL=http://localhost:8080
```

Open http://localhost:8080 (Jaspr picks the next available port if 8080 is taken).

---

## Deployment

### Frontend — Firebase Hosting

```bash
# Build the Jaspr frontend (point to your production backend URL)
cd frontend
jaspr build --dart-define=API_BASE_URL=https://your-backend-url.onrender.com
cd ..

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

### Backend — Render

1. Push the repo to GitHub
2. Create a new **Web Service** on [Render](https://render.com) (free tier)
3. Set the root directory to `server`
4. Build command: `npm install && npm run build`
5. Start command: `npm start`
6. Add environment variables:
   - `GROQ_API_KEY` — your Groq API key
   - `FIREBASE_SERVICE_ACCOUNT` — the full service account JSON (single line)

### Firestore — Firebase Console

1. Go to Firebase Console > Build > Firestore Database
2. Create a database (production mode, any region)
3. Deploy security rules: `firebase deploy --only firestore:rules`
4. Deploy indexes: `firebase deploy --only firestore:indexes`

---

## Environment Variables

| Variable | Where | Description |
|----------|-------|-------------|
| `GROQ_API_KEY` | `server/.env` | Groq API key (free at console.groq.com) |
| `FIREBASE_SERVICE_ACCOUNT` | `server/.env` | Firebase service account JSON (single line) |
| `PORT` | `server/.env` | Server port (default: 8080) |
| `API_BASE_URL` | Dart `--dart-define` | Backend URL passed to frontend at build time |

---

## Firestore Collections

### `opportunities`

| Field | Type | Description |
|-------|------|-------------|
| title | string | Opportunity name |
| type | string | scholarship, internship, fellowship, summit, exchange |
| country | string | Country or region |
| field | string | Field of study |
| educationLevel | string | undergraduate, graduate, phd, any |
| deadline | string | Application deadline |
| description | string | Short description |
| applicationLink | string | URL to apply |

### `chats`

| Field | Type | Description |
|-------|------|-------------|
| userId | string | Session identifier |
| message | string | Message content |
| role | string | "user" or "assistant" |
| timestamp | timestamp | Server timestamp |

---

## Voice Input

The chat interface includes a microphone button that uses the **Web Speech API**:

1. Click the microphone button (between the input field and Send)
2. Speak your question — the button pulses red while listening
3. Your speech is converted to text and automatically sent

**Browser support:** Chrome, Edge, Safari. The mic button only appears if the browser supports the API.

---

## License

MIT
