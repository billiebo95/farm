# Аптека Опт

Flutter implementation of the `Аптека Опт v2.dc.html` design (pharmacy
wholesale ordering app). Source design bundle: `../README.md`, `../chats/`,
`../project/`.

## Scope of this pass

This is a **UI-only** build, by explicit agreement with the design's owner:
every screen and interaction from the prototype is implemented and wired to
a local, in-memory store (`lib/state/app_state.dart`) seeded with mock data
(`lib/data/mock_data.dart`). There is **no backend, no real Google Drive
price sync, and no real DBF/1С export** yet — those are simulated (fake
network delay, then a toast/status change).

Screens implemented:

- Delivery-code login
- 3-step pharmacy registration (license details → address → pending review)
- Price catalog: search, filters, dense product cards, product detail sheet
- Cart / checkout with min-order validation and a comment field
- Order history + order detail (with the DBF-columns "waiting for your
  structure" stub, per the design chat — see `../chats/chat1.md`)
- Profile (pharmacy card, region selector, price/discount info)
- Supplier PIN lock (`5727`) + admin panel (global/per-client discounts,
  price & DBF info, all-client orders with a region filter)

## Architecture

- `lib/state/app_state.dart` — single `ChangeNotifier` store holding
  navigation, cart, discounts, search/filter and admin state. It is a
  straight port of the pricing/discount math and state machine authored in
  the prototype's `Component` class.
- `lib/data/mock_data.dart` — the price list / client registry / order
  history stand-ins for the real backend.
- `lib/screens/*`, `lib/widgets/*` — presentation, matching the prototype's
  visual spec (`lib/theme/app_theme.dart` carries the colors/type scale:
  accent `#1F6F5C`, calm/clinical white).

The prototype's `ios-frame.jsx` / `android-frame.jsx` (device bezel/status
bar mockup chrome) and `support.js` (the design tool's own template
runtime) are **not** ported — a real device supplies its own status bar and
chrome, and the runtime was internal to the prototyping tool, not part of
the app design.

## Known gaps / next steps

Flagged by the design owner as still open in the source chats, or out of
scope for this pass:

1. **Backend** — no API yet. Planned target: Firebase (per the design
   conversation), for auth-by-delivery-code, the price catalog, orders and
   discounts.
2. **Google Drive price sync** — `AppState.syncPrice()` simulates the read;
   needs a real Drive integration.
3. **DBF export** — column names/types/lengths were never supplied by the
   pharmacy owner (see `../chats/chat1.md`); the order detail and admin
   panel show the same placeholder columns as the prototype.
4. **Barcode scanner** — the scan button currently just shows a toast.
5. Fonts fall back to the platform default; the design's monospace accents
   (codes, prices) use the generic `monospace` family rather than a bundled
   font.

## Running

```
flutter pub get
flutter run
```

`flutter analyze` and `flutter test` are clean as of this pass.
