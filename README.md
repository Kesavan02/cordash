# CorDash - Health Connect Realtime Dashboard (Android)

CorDash is a zero-network-I/O Flutter application built with Clean Architecture that subscribes to Android Health Connect for real-time **Steps** and **Heart Rate** updates, presenting custom interactive graphics (`CustomPainter`) and an active Performance HUD overlay.

---

## Anti-Plagiarism & Authenticity Enforcement

- **Package Name**: `com.example.cordash`
- **First Git Commit Hash**: `4b8fea420da7b41d0a7c59535ddfaacfb0bc6e6e`
- **Formula**: `SHA256("${packageName}:${firstGitCommitHash}")` (lowercase hex)
- **Derived Anti-Plagiarism SALT**:
  ```text
  53e4cf58eb6634c6149e062b2110da8712b6f9d1403a1d7b735589004348d5c7
  ```
This SALT is embedded in [`lib/core/constants/app_constants.dart`](file:///c:/D/personal/cordash/lib/core/constants/app_constants.dart) and Android [`AndroidManifest.xml`](file:///c:/D/personal/cordash/android/app/src/main/AndroidManifest.xml).

---

## Architecture Overview (Clean Architecture)

- **`lib/domain/`**: Pure Dart layer defining entities (`StepRecordEntity`, `HeartRateRecordEntity`, `PermissionStatusEntity`), abstract repository contracts, and use cases.
- **`lib/data/`**: Data sources (Kotlin `EventChannel` Native Bridge, `SimSource` Debug emitter), deduplication service, and LTTB decimation algorithms.
- **`lib/presentation/`**: `provider` state management, custom zero-allocation `CustomPainter` charts, interactive gesture layers, and real-time Performance HUD.

---

## Getting Started & Execution

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```
2. **Run Unit Tests**:
   ```bash
   flutter test test/unit/salt_verifier_test.dart
   ```
3. **Target Android SDK**:
   - Target SDK: 34 (Android 14)
   - Minimum SDK: 26 (Android 8.0 Oreo)
