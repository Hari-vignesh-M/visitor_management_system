# Visitor Management System

A Flutter Android app for front-desk and security staff to register visitors, generate and scan visitor QR codes, and record check-in / check-out.

## Versions

- Flutter 3.47.6 (stable)
- Dart 3.13.5
- Platform: Android

## Features

- **Dashboard**: Total Visitors Today, Currently Checked In and Checked Out Today. Counts are worked out from the visitor list returned by the API, using the device's local date. Also has quick actions (Register, Scan QR, Visitor List) and recent visitors.
- **Register / Edit visitor**:
  - Validation: name, mobile (exactly 10 digits) and purpose are required; email is optional but checked when entered.
  - Dropdowns for visitor type and project.
  - A new visitor starts with status `Registered`.
  - After saving, the app shows a confirmation and opens the visitor's details with their QR code.
- **Visitor list**:
  - Search by name or mobile.
  - Filter by status chips and by project.
  - Pull to refresh.
  - Edit and delete (with confirmation) on each card; tap a card to open its details.
- **Visitor details**: profile, status chip, registered / check-in / check-out times, QR code, and a Check In or Check Out button depending on the status.
- **QR scanner**:
  - Camera preview with a scan frame and a torch toggle.
  - Rejects invalid QR codes and shows an error for visitors that don't exist.
  - Opens visitor details after a successful scan.
  - Shows a message when camera permission is denied.
- **Status workflow**: `Registered → Checked In → Checked Out`.
  - You can't check out before checking in, check in twice, or check in again after a visit is completed.
  - Before every status change the app fetches the latest record from the API, so stale data can't cause a duplicate check-in.
  - Repeated taps or scanner callbacks are ignored while a request is running.
- **UI states**: loading, empty list, no search results, network errors (with retry), validation errors, invalid QR codes, and failed status updates.
- **Bonus**: filters, pull to refresh, tappable dashboard stats (open the list already filtered), a visit timeline, and unit tests.

## Packages

| Package | Purpose |
|---|---|
| provider | State management |
| dio | REST API client |
| go_router | Navigation (bottom-nav shell + full-screen routes) |
| qr_flutter | QR code generation |
| mobile_scanner | QR scanning with the camera |
| intl | Date formatting |

## State management: Provider

The assignment needs the same visitor data to stay in sync across the list, details and dashboard. Provider with `ChangeNotifier` handles this simply:

- `VisitorViewModel` is registered once at app start (`main.dart`). It holds the visitor list, and the dashboard counts and search/filter results are computed from that list.
- When a visitor is created, edited, deleted, checked in or checked out, the ViewModel updates that one record in the list and calls `notifyListeners()`. The dashboard, list and details screens all rebuild with the new data, without a restart or another fetch.
- `ScannerViewModel` is created only for the scanner screen. It validates the QR, looks up the visitor through `VisitorViewModel`, and blocks duplicate scanner callbacks.
- Widgets never call the API directly. The layers are **UI → ViewModel → Repository → ApiClient (Dio)**.

## Project structure

```
lib/
├── main.dart / app.dart          # Providers, MaterialApp.router, theme
├── routes/                       # go_router paths and pages
├── services/                     # ApiClient (Dio) + AppException types
├── data/
│   ├── models/visitor/           # VisitorModel, VisitorStatus (JSON <-> Dart)
│   └── repositories/visitor/     # VisitorRepository (CRUD + status update)
├── viewModel/                    # BaseViewModel, VisitorViewModel, ScannerViewModel
├── ui/                           # dashboard, home (bottom nav), visitor list/form/details, scanner
├── common_widgets/               # CustomTextField, CustomButton, StatusChip, LoadingView,
│                                 # EmptyStateWidget, ErrorBanner, confirm dialog, toasts
└── utils/                        # theme, colors, constants, validators, date & QR helpers
```

## Mock API (MockAPI.io)

1. Create a project at <https://mockapi.io> and add a resource named **`visitors`**.
2. Set up the schema with these fields (all type *String*, except `id`, which MockAPI generates):
   `name, mobile, email, visitor_type, project, purpose, status, created_at, check_in_time, check_out_time`.
   Remove MockAPI's default fields (`createdAt`, `avatar`) if they are present.
3. Copy the project URL, for example `https://<project-id>.mockapi.io/api/v1/`.

The app uses these endpoints:

| Method | Endpoint | Use |
|---|---|---|
| GET | `/visitors` | List visitors |
| GET | `/visitors/{id}` | Visitor details / QR lookup |
| POST | `/visitors` | Register visitor |
| PUT | `/visitors/{id}` | Edit visitor, check-in, check-out |
| DELETE | `/visitors/{id}` | Delete visitor |

**Base URL:** `https://6ae1d044bbb54129229932f4.mockapi.io/api/v1/`

### Sample record

```json
{
  "id": "1",
  "name": "Rahul Sharma",
  "mobile": "9876543210",
  "email": "rahul@example.com",
  "visitor_type": "Customer",
  "project": "Project A",
  "purpose": "Site Visit",
  "status": "Registered",
  "created_at": "2026-10-26T10:00:00+05:30",
  "check_in_time": null,
  "check_out_time": null
}
```

## Setup and running

The base URL is set in `lib/utils/constants/end_points_constants.dart`. You can also pass it at build time:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://<project-id>.mockapi.io/api/v1/
```

Build the APK:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://<project-id>.mockapi.io/api/v1/
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

Run the tests:

```bash
flutter test
```

## QR code format

The QR code contains the server-generated visitor ID with an app prefix, for example `VMS:12`. The prefix lets the scanner reject unrelated QR codes (URLs, Wi-Fi codes and so on) before calling the API. A bare ID such as `12` is also accepted.

## Known limitations

- One visit per registration, as the assignment allows. Visit history is not stored.
- MockAPI has no server-side rule for status changes. The app checks the rules against the latest server record just before saving, but two devices tapping at the exact same moment could still both succeed.
- MockAPI returns HTTP 500 instead of 404 when you request a visitor ID that doesn't exist. On a 500, the repository checks the visitor list, so a missing visitor still shows "Visitor not found".
- Data isn't cached offline, so the app needs an internet connection.
- The release APK is signed with the debug key.

## Screenshots

_Add screenshots of: Dashboard, Visitor List, Visitor Registration, Visitor Details & QR Code, QR Scanner._
