# Well Spent

Well Spent is a private, offline-first expense tracker. It stores expenses and budget settings in the browser’s `localStorage`; no account or backend is required.

## Features

- Add expenses with category, date, and simple `+`/`-` amount formulas.
- Weekly, monthly, and yearly spending views with configurable monthly cycle start day.
- Budget progress, daily velocity, end-of-period forecast, and category breakdown.
- Day-wise and month-wise spending trend chart.
- Category filters, delete actions, CSV export/import, responsive layout, and installable PWA support.

## Run locally

Because service workers require an HTTP origin, serve the project with any small static server:

```bash
python3 -m http.server 8080
```

Open <http://localhost:8080> in a browser. The app is also suitable for static hosting (GitHub Pages, Netlify, or similar).

## Data and privacy

Data is kept locally in the browser under the `well_spent_*` storage keys. Clearing site data removes it. Use **Export CSV** regularly if the data matters; **Import CSV** restores a Well Spent export and replaces the current expenses.

The service worker caches the local app shell for offline use. The Google Fonts stylesheet is optional; the app falls back to system fonts when offline.

## Project layout

- `index.html`, `styles.css`, `app.js` — the runnable web/PWA app.
- `sw.js`, `manifest.json`, `icon.*` — offline and install metadata.
- `lib/`, `pubspec.yaml` — an additional Flutter implementation skeleton for native builds.

## Limitations

This version intentionally has no cloud sync, authentication, bank integrations, or cross-device backup. Browser storage is device/profile-specific.
