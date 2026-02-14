# Social & Instagram Setup

## Overview

The app supports:

1. **Share achievements** – Users can share achievements (or "I'm in FBLA") to Instagram, Twitter, or any app via the system share sheet.
2. **National / State / Chapter Instagram** – Links to open each FBLA Instagram profile in the Instagram app or browser.
3. **Featured posts** – Curated Instagram post URLs stored in Firestore, shown in the Social tab.

This setup supports **explicit Instagram URLs** (preferred) and **handles** (fallback) so you are not relying on a strict `https://instagram.com/<handle>` pattern.

---

## Firestore configuration

### 1) Social config (National + State profile URLs / handles)

Create a document (or merge into existing config):

- **Collection:** `social_config`
- **Document ID:** `instagram`

**Fields**

**National**
- `nationalInstagramUrl` (string, recommended) – full profile URL  
  - e.g. `https://www.instagram.com/fbla_national/`
- `nationalInstagramHandle` (string, optional) – username only (no `@`)  
  - e.g. `fbla_national`

**Default state fallback**
- `defaultStateInstagramUrl` (string, optional) – used when a state is not found in maps
- `defaultStateInstagramHandle` (string, optional) – fallback handle if URL is not set

**State overrides**
- `stateInstagramUrls` (map, optional) – state key → full Instagram profile URL  
  - e.g. `CA` → `https://www.instagram.com/californiafbla/`
- `stateInstagramHandles` (map, optional) – state key → Instagram username (no `@`)  
  - e.g. `CA` → `californiafbla`

**Example**

```json
{
  "nationalInstagramUrl": "https://www.instagram.com/fbla_national/",
  "nationalInstagramHandle": "fbla_national",

  "defaultStateInstagramUrl": "https://www.instagram.com/fbla_national/",
  "defaultStateInstagramHandle": "fbla_national",

  "stateInstagramUrls": {
    "CA": "https://www.instagram.com/californiafbla/",
    "TX": "https://www.instagram.com/texasfbla/",
    "Georgia": "https://www.instagram.com/gafbla/"
  },
  "stateInstagramHandles": {
    "CA": "californiafbla",
    "TX": "texasfbla",
    "Georgia": "gafbla"
  }
}
