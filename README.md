# Well Spent

Well Spent is a private, offline-first expense tracker. It stores expenses and budget settings in the browser’s `localStorage`; no account or backend is required.

## Project status

The browser/PWA implementation is currently at **v1.0.0-alpha**. The Flutter implementation is an active native-app workstream: the local Flutter SDK is installed and dependencies resolve, but native analysis still has compatibility errors to address.

## Delivery phases

| Phase | Status | Scope |
| --- | --- | --- |
| 1. Core expense tracking | ✅ Complete | Add, view, filter, and delete expenses with categories, dates, and quick amount formulas. |
| 2. Budgets and insights | ✅ Complete | Weekly, monthly, and yearly views; budget progress; velocity and period-end forecasting; category breakdowns; day-wise and month-wise trends. |
| 3. Data portability and offline web app | ✅ Complete | CSV import/export, responsive UI, installable PWA metadata, and service-worker app-shell caching. |
| 4. Native Flutter app | 🚧 In progress | Flutter 3.44.8/Dart 3.12.2 is installed locally; dashboard, analytics, SQLite persistence, CRUD operations, and forecast services are scaffolded. API compatibility fixes, native build validation, parity, and release polish remain. |
| 5. Cloud and integrations | ⏳ Planned | Optional authentication, cloud sync, cross-device backup, and bank integrations. |

**Current focus:** finish and validate the Flutter/native implementation while maintaining the browser/PWA experience.

## Features

- Add expenses with category, date, and simple `+`/`-` amount formulas.
- Track recurring base income by pay day and add one-off income entries from the same entry form.
- Weekly, monthly, and yearly spending views with configurable monthly cycle start day.
- Budget progress remains spending-versus-budget focused, with earned income, budgeted/spent totals, net remaining, and savings-target context.
- Savings-rate tracking, payday-based safe daily burn, and fixed-versus-variable expense insights.
- Configurable in-app spending summaries for yesterday, the last 7 days, or the current month, with period comparisons and top-category breakdowns.
- Daily velocity, end-of-period forecast, and category breakdown.
- Day-wise and month-wise spending trend chart.
- Category filters, delete actions, CSV export/import, responsive layout, and installable PWA support.

## Run locally

Because service workers require an HTTP origin, serve the project with any small static server:

```bash
python3 -m http.server 8080
```

Open <http://localhost:8080> in a browser. The app is also suitable for static hosting (GitHub Pages, Netlify, or similar).

### Native Flutter setup

The project uses a local Flutter SDK at `.flutter-sdk/` (ignored by Git). From the project root:

```bash
./.flutter-sdk/bin/flutter pub get
./.flutter-sdk/bin/flutter analyze
```

The current native implementation is not yet analysis-clean. The remaining blockers are Flutter API compatibility updates in the theme configuration and widget font weights.

## Data and privacy

Data is kept locally in the browser under the `well_spent_*` storage keys. Expenses and one-off income share the existing entries storage with a `type` of `expense` or `income`; expenses also carry an `expenseKind` of `fixed` or `variable`. Recurring income and pay-day settings have their own keys. Clearing site data removes it. Use **Export CSV** regularly if the data matters; **Import CSV** restores a Well Spent export and replaces the current entries.

The service worker caches the local app shell for offline use. The Google Fonts stylesheet is optional; the app falls back to system fonts when offline.

## Project layout

- `index.html`, `styles.css`, `app.js` — the runnable web/PWA app.
- `sw.js`, `manifest.json`, `icon.*` — offline and install metadata.
- `lib/`, platform folders, and `pubspec.yaml` — the Flutter implementation for native builds.

## Limitations

This version intentionally has no cloud sync, authentication, bank integrations, or cross-device backup. Browser storage is device/profile-specific.
