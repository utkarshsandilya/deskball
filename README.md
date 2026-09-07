# Deskball Federation

Free to host, installs on any phone, and everyone shares one live league.

The app runs in one of two modes:

- **Offline** (out of the box) — everything saves to that browser. Each phone has its own separate league.
- **Live** (after the Supabase setup below) — one shared league, real accounts, changes appear on everyone's screen within a second.

---

## 1. Put it online (5 minutes, free)

1. Sign up at **vercel.com** — the Hobby plan is free, no card.
2. **Add New → Project → Deploy**, and drag this folder in.
3. You get a URL like `deskball.vercel.app`. Share it.

If you'll keep changing it, put the folder in a GitHub repo and **Import** that instead — every push redeploys in seconds. Netlify, Cloudflare Pages and GitHub Pages work the same way and are also free.

### Onto a home screen
- **Android / Chrome** — ⋮ menu → **Install app**.
- **iPhone / Safari** — Share → **Add to Home Screen**. Must be Safari; Chrome on iOS can't install.

It then opens fullscreen with its own icon.

### Updates
`sw.js` is **network-first**: every open fetches your current version, so a redeploy reaches everyone the next time they open the app. Nothing to update by hand, no store review. The last version they loaded stays cached so it still opens on bad wifi.

---

## 2. Make it live and shared (about 15 minutes, also free)

### a. Create the project
1. Sign up at **supabase.com** and create a new project. Keep the region near you.
2. **SQL Editor → New query**, paste all of **`schema.sql`**, press **Run**. That creates the tables and the security rules.

### b. Turn off email confirmation
**Authentication → Sign In / Providers → Email** and switch **Confirm email** off. Otherwise everyone has to click a link in an inbox before they can sign in — fine for adults, painful for a school club.

### c. Point the app at it
**Project Settings → API** gives you a **Project URL** and an **anon public** key. Open `index.html`, find this line near the top of the script (search for `const CLOUD`):

```js
const CLOUD={ url:'', anon:'' };
```

Fill both in:

```js
const CLOUD={ url:'https://abcdefgh.supabase.co', anon:'eyJhbGciOi...' };
```

Redeploy. That's it — the app switches to live mode on its own.

> The anon key is *designed* to be public. It identifies your project, it doesn't grant anything. What actually protects your data is the row-level security in `schema.sql`, enforced by the server.

### d. Make yourself the admin
1. Open the app and **Register** with your name, email and a password.
2. In Supabase: **Table Editor → `admins` → Insert row**, and paste your user id (find it under **Authentication → Users**).
3. Reload the app. You're the admin.

There is deliberately no way to make yourself admin from inside the app.

### e. Everyone else
They open the link, **Register**, and appear in your **Requests** screen. Tap **Add to roster** and they're in. From then on they can see the live ladder and ask for skill updates, which you approve or decline.

---

## What changed versus the offline version

- **Real accounts.** Email and password, hashed by Supabase. The old `DESKBALLADMIN` / `itisthatserious` login is gone — it only ever existed in offline mode, and it was readable in the page source.
- **Real permissions.** "Only the admin can change ratings" is now enforced by the database, not by the page. A player editing the JavaScript in their browser still cannot write to the league — the server rejects it.
- **Live updates.** Record a match and it appears on every open phone within about a second, over a websocket. No refreshing.
- **`DB1-` request codes are no longer needed** — requests go straight to the database.

## Worth knowing

- **The whole league is one row of JSON**, and only admins write it. That is simple and fast at club scale, but it means two admins editing at the same moment can overwrite each other. With one admin — the normal case — it never comes up.
- **Free tiers pause on inactivity.** A Supabase project with no traffic for a week or so gets paused; you un-pause it from the dashboard in one click. Check current limits, they change.
- **Backups.** Setup → Export league still works and still writes a JSON file. Worth doing at the end of a term.

## Files

| File | What it is |
| --- | --- |
| `index.html` | The whole app. Edit `const CLOUD` near the top to go live. |
| `schema.sql` | Tables, security rules and realtime. Paste into Supabase once. |
| `manifest.webmanifest` | Name, colours and icons for "Add to Home Screen". |
| `sw.js` | Service worker — offline fallback and automatic updates. |
| `icon-192.png`, `icon-512.png`, `apple-touch-icon.png` | App icons. |
