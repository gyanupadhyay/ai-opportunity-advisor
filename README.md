# AI Opportunity Advisor (Vedixa AI)

An AI-powered chatbot that helps students discover scholarships, internships, fellowships, exchange programs, and global opportunities through a conversational interface with smart quick-reply suggestions.

**Tech Stack:** Jaspr (Dart) frontend, Express.js backend, Groq AI (Llama 3.3 70B), Firebase Firestore, Web Speech API for voice input.

---

## Architecture

```
User  →  Jaspr Web App (Firebase Hosting)  →  Express API (Render)  →  Groq AI + Firestore  →  Response
```

| Layer | Technology | Hosting |
|-------|-----------|---------|
| Frontend | Jaspr (Dart → JS SPA) | Firebase Hosting (free Spark plan) |
| Backend API | Express.js + TypeScript | Render (free tier) |
| AI Model | Groq — Llama 3.3 70B Versatile | Groq API (free tier) |
| Database | Cloud Firestore | Firebase (free Spark plan) |

---

## Features

- **Conversational onboarding** — the AI asks about your country, education level, field of study, and interests
- **Quick reply chips** — clickable options appear for common questions (education level, field, region, etc.)
- **Opportunity matching** — recommends scholarships, internships, fellowships, and more from Firestore
- **Voice input** — click the mic button to speak your answer (Chrome, Edge, Safari)
- **Admin panel** — password-protected `/admin` UI to add, edit, and delete opportunities in Firestore
- **AI-powered seed script** — generate 200+ realistic opportunities using Groq and write them to Firestore
- **Responsive, animated UI** — fluid scaling with `clamp()`, `dvh`, `min()`, and polished CSS animations (landing, chat, cards, chips)

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
│   │   │   ├── chat_widget.dart        # Main chat UI, message list, quick replies
│   │   │   ├── chat_input_bar.dart     # Text input + mic + send (isolated state)
│   │   │   ├── message_bubble.dart     # Single message renderer
│   │   │   ├── opportunity_card.dart   # Opportunity card in chat
│   │   │   └── opportunity_form.dart   # Reusable admin add/edit opportunity form
│   │   ├── pages/
│   │   │   ├── home_page.dart          # Landing page
│   │   │   ├── chat_page.dart          # Chat page wrapper
│   │   │   └── admin_page.dart         # Admin panel UI (/admin)
│   │   ├── models/                     # message, opportunity
│   │   ├── services/
│   │   │   ├── api_service.dart        # HTTP calls to backend (user + admin)
│   │   │   └── speech_service.dart     # Web Speech API wrapper
│   │   ├── app.dart                    # Router setup
│   │   ├── constants.dart              # Frontend-wide constants (routes, roles, types, endpoints)
│   │   └── main.client.dart
│   ├── web/
│   │   ├── index.html                 # Entry + SEO meta, OG, JSON-LD
│   │   ├── styles.css                 # All styles (responsive, clamp, dvh)
│   │   ├── robots.txt                 # Crawler rules + sitemap URL
│   │   └── sitemap.xml                # URL list for search engines
│   └── pubspec.yaml
├── server/                     # Express.js backend (for Render deployment)
│   ├── src/
│   │   ├── index.ts                    # Express app, routes, /health, CORS, rate limiting
│   │   ├── config.ts                   # Centralised backend config (model, collections, limits, CORS)
│   │   ├── chat_handler.ts             # POST /handleChatMessage handler
│   │   ├── firebase.ts                 # Firebase Admin SDK init
│   │   ├── recommendation_engine.ts    # Conversation orchestration + opportunity matching
│   │   ├── admin_routes.ts             # /admin/opportunities CRUD (password-protected)
│   │   ├── services/
│   │   │   ├── ai_service.ts           # Groq API integration
│   │   │   ├── user_service.ts         # Conversation + chat logging in Firestore
│   │   │   └── opportunity_service.ts  # Firestore queries and filters
│   │   ├── models/
│   │   │   ├── user_model.ts           # User profile types
│   │   │   └── opportunity_model.ts    # Opportunity types + type mapping
│   ├── package.json
│   ├── tsconfig.json
│   └── .env.example
├── generate_opportunities.js   # AI-powered Firestore opportunity seeder using Groq
├── functions/                  # Firebase Cloud Functions (alternative backend, optional)
│   ├── src/
│   │   └── ...                        # Older logic, kept for reference
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
PORT=3000
ADMIN_PASSWORD=your-admin-password-here
FIREBASE_SERVICE_ACCOUNT={"type":"service_account",...}

# CORS — comma-separated allowed origins (localhost is always included by default)
CORS_ORIGINS=https://your-hosted-frontend.web.app,https://your-hosted-frontend.firebaseapp.com

# Rate limiting for the chat endpoint
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX=30

# AI model tuning (optional overrides)
AI_MODEL=llama-3.3-70b-versatile
AI_TEMPERATURE=0.7
```

- **Groq API key** — get one free at https://console.groq.com  
- **Firebase service account** — download from Firebase Console > Project Settings > Service Accounts > Generate new private key, then paste the entire JSON as a single line  
- **ADMIN_PASSWORD** — simple shared password required to access `/admin` and perform CRUD on opportunities

### 3. Seed Firestore with Sample / AI-Generated Data

You have two options:

- **Legacy sample seeder**: `seed_firestore.js` (small, fixed dataset)  
- **AI-powered seeder**: `generate_opportunities.js` (recommended — 200+ realistic opportunities)

```bash
# Install firebase-admin and groq-sdk at root (if not already)
npm install firebase-admin groq-sdk dotenv

# Ensure GROQ_API_KEY and FIREBASE_SERVICE_ACCOUNT are set (from server/.env)

# AI-powered seeding (recommended)
node generate_opportunities.js

# Or legacy seeding (small sample set)
node seed_firestore.js
```

### 4. Start the Backend

```bash
cd server
npm run build && npm start
```

The API will be available at `http://localhost:3000` (or the `PORT` you set). Test with:
```bash
curl http://localhost:3000/health
```

### 5. Start the Frontend

```bash
cd frontend
jaspr serve --dart-define=API_BASE_URL=http://localhost:3000
```

By default Jaspr serves the frontend on `http://localhost:8080` (or the next free port).  
The frontend always calls the backend using the `API_BASE_URL` you pass via `--dart-define`.

---

## Deployment

### Frontend — Firebase Hosting

Ensure `sitemap.xml` and `robots.txt` are in the build output so Google can fetch the sitemap:

```bash
# 1. Build the Jaspr frontend (point to your production backend URL)
cd frontend
jaspr build --dart-define=API_BASE_URL=https://your-backend-url.onrender.com
cd ..

# 2. Copy SEO files into build (required for sitemap/robots to be served)
npm run deploy:hosting
```

Or run the copy step manually, then deploy:

```bash
# Copy sitemap and robots into frontend/build/jaspr, then deploy
node scripts/copy-seo.mjs
firebase deploy --only hosting
```

`firebase.json` rewrites `/sitemap.xml` and `/robots.txt` to these static files before the SPA catch-all so they are always served correctly.

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
| `PORT` | `server/.env` | Server port (default: `3000`) |
| `ADMIN_PASSWORD` | `server/.env` | Password required for `/admin` CRUD endpoints |
| `CORS_ORIGINS` | `server/.env` | Extra allowed origins for CORS (comma-separated, frontend hosting URLs) |
| `RATE_LIMIT_WINDOW_MS` | `server/.env` | Rate limit window for the chat endpoint (default `60000` ms) |
| `RATE_LIMIT_MAX` | `server/.env` | Max requests per window per IP for chat endpoint (default `30`) |
| `AI_MODEL` | `server/.env` | Optional override for Groq model name (defaults to `llama-3.3-70b-versatile`) |
| `AI_TEMPERATURE` | `server/.env` | Optional override for model temperature (defaults to `0.7`) |
| `API_BASE_URL` | Dart `--dart-define` | Backend base URL passed to frontend at build time |

---

## Firestore Collections

### `opportunities`

| Field | Type | Description |
|-------|------|-------------|
| title | string | Opportunity name |
| type | string | `scholarship`, `internship`, `fellowship`, `research`, `exchange`, `summit` |
| country | string | Country or region |
| field | string | Field of study |
| educationLevel | string | `undergraduate`, `graduate`, `phd`, `any` |
| deadline | string | Application deadline |
| description | string | Short description |
| applicationLink | string | URL to apply |
| source | string | `ai-generated` or `manual` |
| createdAt | timestamp | Server timestamp (when document was created) |

### `chats`

| Field | Type | Description |
|-------|------|-------------|
| userId | string | Session identifier |
| message | string | Message content |
| role | string | `"user"` or `"assistant"` |
| timestamp | timestamp | Server timestamp |

### `conversations`

| Field | Type | Description |
|-------|------|-------------|
| messages | array | Full chat history (role + content) for the session |
| profile | object | Structured student profile inferred by the AI |
| profileQueried | bool | Whether Firestore has already been queried for this profile |
| updatedAt | timestamp | Last update time (server timestamp) |

---

## Voice Input

The chat interface includes a microphone button that uses the **Web Speech API**:

1. Click the microphone button (between the input field and Send)
2. Speak your question — the button pulses red while listening
3. Your speech is converted to text and automatically sent

**Browser support:** Chrome, Edge, Safari. The mic button only appears if the browser supports the API.

---

## SEO

The site is set up for search and social sharing:

- **Meta**: Title, description, keywords, canonical URL, `robots: index, follow`
- **Open Graph** & **Twitter Card**: For link previews on social platforms
- **JSON-LD**: `WebApplication` schema for search engines
- **`robots.txt`** and **`sitemap.xml`** in `frontend/web/` (included in build output)

To improve Google visibility:

1. **Google Search Console**: Add property `https://ai-opportunity-advisor.web.app`, verify ownership, then submit the sitemap: **`https://ai-opportunity-advisor.onrender.com/sitemap.xml`** (served by the backend so GSC can always fetch it; the sitemap still lists your Firebase Hosting URLs).
2. **Social image**: Add `frontend/web/og-image.png` (e.g. 1200×630) for richer previews when the site is shared; the build will serve it at `/og-image.png`

**If GSC shows "Couldn't fetch" for the sitemap:** The sitemap is also served by the backend at `https://ai-opportunity-advisor.onrender.com/sitemap.xml`. Submit that URL in the Sitemaps report instead of the Firebase Hosting URL. `robots.txt` already points to this backend URL.

**Browser console "Unchecked runtime.lastError: Could not establish connection. Receiving end does not exist."** — This comes from a browser extension (e.g. React DevTools, password manager, ad blocker), not from the app. You can ignore it or disable extensions to clear the message.

---

## License

MIT
