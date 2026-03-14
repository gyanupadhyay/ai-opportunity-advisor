# Firestore Database Schema

This document describes the Firestore collections used by Pathora AI.

---

## Collection: `opportunities`

Stores the global opportunities that Pathora AI recommends to students.

| Field           | Type   | Description                                          |
|-----------------|--------|------------------------------------------------------|
| title           | string | Name of the opportunity                              |
| type            | string | `scholarship`, `internship`, `fellowship`, `research`, `summit`, `exchange` |
| country         | string | Country or region (e.g. "Germany", "Europe", "Global") |
| field           | string | Field of study (e.g. "Computer Science", "Multiple Fields") |
| educationLevel  | string | Target level: `undergraduate`, `graduate`, `phd`, `any` |
| deadline        | string | Application deadline (e.g. "December 2026")          |
| description     | string | Short description of the opportunity                 |
| applicationLink | string | URL to the application page                          |

### Example document

```json
{
  "title": "DAAD Scholarship",
  "type": "scholarship",
  "country": "Germany",
  "field": "Multiple Fields",
  "educationLevel": "graduate",
  "deadline": "October 2026",
  "description": "Scholarships for international students at German universities.",
  "applicationLink": "https://www.daad.de/en/"
}
```

---

## Collection: `users`

Stores user profile information (for future auth integration).

| Field     | Type   | Description                        |
|-----------|--------|------------------------------------|
| name      | string | Student's full name                |
| email     | string | Email address                      |
| country   | string | Country of origin                  |
| field     | string | Field of study                     |
| interests | string | Comma-separated interests / goals  |

---

## Collection: `chats`

Append-only log of every message exchanged, useful for analytics.

| Field     | Type      | Description                          |
|-----------|-----------|--------------------------------------|
| userId    | string    | Session ID that sent the message     |
| message   | string    | The message text                     |
| role      | string    | `user` or `assistant`                |
| timestamp | timestamp | Server-generated timestamp           |

---

## Collection: `conversations`

Stores the full conversation state per session, including the extracted
student profile and whether Firestore has already been queried.

| Field          | Type      | Description                                     |
|----------------|-----------|-------------------------------------------------|
| messages       | array     | Array of `{ role, content }` message objects     |
| profile        | map/null  | Extracted `StudentProfile` or null               |
| profileQueried | boolean   | Whether opportunities have been fetched          |
| updatedAt      | timestamp | Server-generated timestamp of last update        |

### StudentProfile shape

```json
{
  "country": "India",
  "educationLevel": "Undergraduate",
  "field": "Computer Science",
  "interests": "AI, software development",
  "opportunityType": "Scholarships",
  "preferredRegion": "Europe",
  "isComplete": true
}
```
