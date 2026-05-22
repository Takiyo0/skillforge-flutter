<p align="center">
  <img src="assets/icons/icon@1240.png" width="90" alt="SkillForge Logo" />
</p>
<p align="center">
  <b>SkillForge</b>: A hands-on learning platform where courses, code challenges, and AI guidance turn practice into measurable progress.
</p>

---

# SkillForge Flutter App

Mobile app client for SkillForge, built with Flutter + Riverpod + GoRouter.

## Tech Stack

- Flutter (Material 3)
- Riverpod (`flutter_riverpod`)
- GoRouter (`go_router`)
- HTTP client (`http`)
- Markdown rendering (`flutter_markdown`)
- Video playback (`video_player`)
- File picker (`file_picker`)

## Requirements

- Flutter SDK (compatible with Dart `^3.10.8`)
- Android Studio or VS Code + Flutter extensions
- Android/iOS emulator or physical device

## Project Structure

```text
lib/
  app/                 # app bootstrap + router
  config/              # app config/constants
  models/              # domain models (admin/auth/shared)
  network/             # API client
  providers/           # app/global providers
  repositories/        # data access (domain-grouped)
  services/            # service abstractions (auth/storage)
  ui/                  # design system, shared UI helpers
  utils/               # cross-cutting helpers/permissions
  view_models/         # presentation logic (domain-grouped)
  views/               # screens (auth/student/admin/shared)
  widgets/             # reusable UI pieces (domain-grouped)
```

## Environments

- Base API URL (BASE_URL)
  - Base URL: `https://skillforge.takiyo.us`
  - Base API: `${BASE_URL}/api/v1`
- Base CDN URL (BASE_CDN_URL)
  - Base CDN: `https://cdn-sf-apac.takiyo.us`

Override at runtime with `--dart-define`:

```bash
flutter run --dart-define=BASE_URL=https://your-api-host.com --dart-define=BASE_CDN_URL=https://your-cdn-host.com
```

## Getting Started

1. Install dependencies

```bash
flutter pub get
```

2. Run app

```bash
flutter run
```

3. Run on a specific device

```bash
flutter devices
flutter run -d <device_id>
```

## Key App Flows

### Authentication

- Login / Register
- Session bootstrap on app start
- Redirect routing based on auth state

### Student Area

- Dashboard
- Browse courses + course detail + units
- Exercise/assessment flow
- Learning paths
- Forums
- Profile/settings/certificates

### Admin Area (role-based)

- Courses + unit management
- Learning paths
- Badges
- Users

Access is guarded by role checks (`admin` / `instructor`).

## Screenshots

![Frame 2.png](docs/assets/Frame%202.png)
![Frame 3.png](docs/assets/Frame%203.png)
![Frame 4.png](docs/assets/Frame%204.png)
![Frame 5.png](docs/assets/Frame%205.png)
![Frame 6.png](docs/assets/Frame%206.png)
![Frame 7.png](docs/assets/Frame%207.png)
![Frame 8.png](docs/assets/Frame%208.png)
![Frame 9.png](docs/assets/Frame%209.png)