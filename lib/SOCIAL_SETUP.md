# Social & Instagram Setup

## Overview

The app supports:

1. **Share achievements** – Users can share achievements (or "I'm in FBLA") to Instagram, Twitter, or any app via the system share sheet.
2. **National / State / Chapter Instagram** – Links to open each FBLA Instagram profile in the Instagram app or browser.
3. **Featured posts** – Curated Instagram post URLs stored in Firestore, shown in the Social tab.

## Firestore configuration

### 1. Social config (Instagram handles)

Create a document (or merge into existing config):

- **Collection:** `social_config`
- **Document ID:** `instagram`
- **Fields:**
  - `nationalInstagramHandle` (string) – e.g. `"fbla_national"` (https://www.instagram.com/fbla_national/)
  - `defaultStateInstagramHandle` (string, optional) – default when a state isn’t in the map
  - `stateInstagramHandles` (map, optional) – state code → Instagram username, e.g.:
    - `CA` → `californiafbla`
    - `TX` → `texasfbla`
    - `Georgia` → `gafbla`

Example:

```json
{
  "nationalInstagramHandle": "fbla_national",
  "defaultStateInstagramHandle": "fbla_national",
  "stateInstagramHandles": {
    "CA": "californiafbla",
    "TX": "texasfbla"
  }
}
```

### 2. Featured Instagram posts

To show “pulled in” posts in the app, add documents to:

- **Collection:** `featured_instagram_posts`
- **Fields per document:**
  - `url` (string) – full Instagram post URL, e.g. `https://www.instagram.com/p/ABC123/`
  - `source` (string) – `"national"`, `"state"`, or `"chapter"`
  - `caption` (string, optional) – short label for the post
  - `order` (number, optional) – sort order (lower first)
  - `addedAt` (timestamp) – required for the feed query; use Firestore server timestamp when creating the doc

Example (e.g. from Firebase Console or Admin SDK):

```json
{
  "url": "https://www.instagram.com/p/ABC123/",
  "source": "national",
  "caption": "NLC 2025",
  "order": 0,
  "addedAt": "<server timestamp>"
}
```

Note: Instagram’s public API does not allow apps to automatically pull the latest posts from an arbitrary account. Featured posts are therefore curated: an admin (or a backend job with the account’s permission) adds post URLs to this collection, and the app displays them and links to Instagram.

### 3. User profile (state & chapter Instagram)

- **Collection:** `users`
- **Document:** per user
- **Optional fields:**
  - `state` (string) – e.g. `"CA"` or `"Texas"` (used to resolve state FBLA Instagram)
  - `chapterInstagramHandle` (string) – chapter’s Instagram username (no `@`)

Users can set **State** and **Chapter Instagram** at signup. Existing users can be updated by writing these fields to their `users/<uid>` document (or via a future “Edit profile” screen).

## In-app behavior

- **Social tab** – Share achievements, open National / State / Chapter Instagram profiles, and browse featured posts.
- **Profile** – Each achievement card has a **Share** button that opens the share sheet with pre-filled text and #FBLA.
- **Opening Instagram** – “View on Instagram” uses the Instagram app if installed, otherwise the profile/post URL opens in the browser.
