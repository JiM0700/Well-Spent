# Well Spent

Well Spent is a private, offline-first expense tracker. It stores expenses and budget settings in the browser’s `localStorage`; no account or backend is required.

## Project status

The browser/PWA implementation is complete and can run from the web assets in this repository. The Flutter native implementation is active and now includes both macOS and iOS scaffolding:

- Native macOS support has been validated with Xcode and Flutter build tooling.
- The iOS platform was generated and can be deployed to a connected device after Xcode signing is configured.

## Delivery phases

| Phase | Status | Scope |
| --- | --- | --- |
| 1. Core expense tracking | ✅ Complete | Add, view, filter, and delete expenses with categories, dates, and quick amount formulas. |
| 2. Budgets and insights | ✅ Complete | Weekly, monthly, and yearly views; budget progress; velocity and period-end forecasting; category breakdowns; day-wise and month-wise trends. |
| 3. Data portability and offline web app | ✅ Complete | CSV import/export, responsive UI, installable PWA metadata, and service-worker app-shell caching. |
| 4. Native Flutter app | 🚧 In progress | Flutter app is scaffolded for macOS and iOS, including SQLite persistence, dashboard, analytics, forecasts, and device build support. Device signing is the remaining deployment step for real iPhone installs. |
| 5. Cloud and integrations | ⏳ Planned | Optional authentication, cloud sync, cross-device backup, and bank integrations. |

**Current focus:** finish native Flutter feature parity, finalize build compatibility, and enable device deployment.

## Features

- Add expenses with category, date, and simple `+`/`-` amount formulas.
- Track recurring base income by pay day and add one-off income entries from the same entry form.
- Weekly, monthly, and yearly spending views with configurable monthly cycle start day.
- Budget progress remains spending-versus-budget focused, with earned income, budgeted/spent totals, net remaining, and savings-target context.
- Savings-rate tracking, payday-based safe daily burn, and fixed-versus-variable expense insights.
- Configurable in-app spending summaries for yesterday, the last 7 days, or the current month, with period comparisons and top-category breakdowns.
- Progressive-disclosure dashboard: budget status and activity stay prominent while forecasts, charts, summaries, and filters expand on demand.
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

The native implementation passes Flutter analysis with informational notices only. A few Flutter API deprecations and minor const/style suggestions remain for future cleanup.

## Data and privacy

Data is kept locally in the browser under the `well_spent_*` storage keys. Expenses and one-off income share the existing entries storage with a `type` of `expense` or `income`; expenses also carry an `expenseKind` of `fixed` or `variable`. Recurring income and pay-day settings have their own keys. Clearing site data removes it. Use **Export CSV** regularly if the data matters; **Import CSV** restores a Well Spent export and replaces the current entries.

The service worker caches the local app shell for offline use. The Google Fonts stylesheet is optional; the app falls back to system fonts when offline.

## Project layout

- `index.html`, `styles.css`, `app.js` — the runnable web/PWA app.
- `sw.js`, `manifest.json`, `icon.*` — offline and install metadata.
- `lib/`, platform folders, and `pubspec.yaml` — the Flutter implementation for native builds.

## Limitations

This version intentionally has no cloud sync, authentication, bank integrations, or cross-device backup. Browser storage is device/profile-specific.
