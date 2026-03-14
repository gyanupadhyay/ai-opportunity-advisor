# AI Opportunity Advisor

An AI-powered chatbot that helps students discover scholarships, internships, fellowships, exchange programs, and global opportunities.

**Tech Stack:** Jaspr (Dart) frontend, Firebase backend (Cloud Functions + Firestore), OpenAI API, Web Speech API for voice input.

---

## Architecture

```
User  →  Jaspr Web App  →  Firebase Cloud Function  →  OpenAI  →  Firestore  →  Response
```

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
├── frontend/               # Jaspr web app (Dart)
│   ├── lib/
│   │   ├── components/     # chat_widget, message_bubble, opportunity_card
│   │   ├── pages/          # home_page, chat_page
│   │   ├── models/         # message, opportunity
│   │   ├── services/       # chat_service (HTTP), speech_service (Web Speech API)
│   │   ├── app.dart        # Router setup
│   │   └── main.client.dart
│   ├── web/                # HTML + CSS
│   └── pubspec.yaml
├── functions/              # Firebase Cloud Functions (TypeScript)
│   ├── src/index.ts        # handleChatMessage function
│   ├── package.json
│   └── tsconfig.json
├── firebase.json           # Firebase project config
├── firestore.rules         # Security rules
├── firestore.indexes.json  # Composite indexes
├── seed_firestore.js       # Sample data seeder
└── README.md
```

---

## Setup & Run Locally

### 1. Clone and Install

```bash
cd ai-opportunity-advisor

# Install frontend dependencies
cd frontend
dart pub get
cd ..

# Install Cloud Functions dependencies
cd functions
npm install
cd ..
```

### 2. Configure Firebase

```bash
# Login to Firebase
firebase login

# Initialize project (select your Firebase project)
firebase use --add

# Or create a new project
firebase projects:create my-opportunity-advisor
firebase use my-opportunity-advisor
```

### 3. Set OpenAI API Key

```bash
# Copy the example env file
cp functions/.env.example functions/.env

# Edit functions/.env and add your real OpenAI API key
# OPENAI_API_KEY=sk-your-key-here
```

For deployed functions, set the secret:
```bash
firebase functions:secrets:set OPENAI_API_KEY
```

### 4. Seed Sample Data

Start the Firestore emulator first, then seed:

```bash
# Start emulators
firebase emulators:start --only firestore

# In a new terminal, seed data
set FIRESTORE_EMULATOR_HOST=127.0.0.1:8081
node seed_firestore.js
```

### 5. Start the Backend (Firebase Emulators)

```bash
cd functions
npm run build
cd ..
firebase emulators:start --only functions,firestore
```

The Cloud Function will be available at: `http://127.0.0.1:5001/YOUR_PROJECT_ID/us-central1/handleChatMessage`

### 6. Start the Frontend (Jaspr Dev Server)

```bash
cd frontend
jaspr serve
```

Open http://localhost:8080 in your browser.

### 7. Configure API URL

Update the API base URL to point to your local emulator. When running `jaspr serve`, pass:

```bash
jaspr serve --dart-define=API_BASE_URL=http://127.0.0.1:5001/YOUR_PROJECT_ID/us-central1
```

Replace `YOUR_PROJECT_ID` with your actual Firebase project ID.

---

## Voice Input

The chat interface includes a microphone button that uses the **Web Speech API** for speech-to-text:

1. Click the microphone button (appears between the input field and Send)
2. Speak your question — the button pulses red while listening
3. Your speech is converted to text and automatically sent to the chatbot

**Browser support:** Chrome, Edge, Safari (uses `webkitSpeechRecognition`). Firefox supports the standard `SpeechRecognition` API. The mic button only appears if the browser supports the API.

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
| userId | string | Session/user identifier |
| message | string | Message content |
| role | string | "user" or "assistant" |
| timestamp | timestamp | Server timestamp |

### `users`
| Field | Type | Description |
|-------|------|-------------|
| name | string | Student name |
| email | string | Email address |
| country | string | Country |
| field | string | Field of study |
| interests | array | Areas of interest |

---

## Deploying to Production

### Deploy Cloud Functions
```bash
cd functions && npm run build && cd ..
firebase deploy --only functions
```

### Build Frontend
```bash
cd frontend
jaspr build
```

The built files will be in `frontend/build/jaspr/`. Deploy them to Firebase Hosting or any static host.

### Deploy Everything
```bash
firebase deploy
```

---

## Environment Variables

| Variable | Where | Description |
|----------|-------|-------------|
| `OPENAI_API_KEY` | `functions/.env` | Your OpenAI API key |
| `API_BASE_URL` | Dart define | Firebase Functions URL |

---

## License

MIT
