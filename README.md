# CorDash — Android Health Telemetry Dashboard

[![Flutter CI](https://github.com/Kesavan02/cordash/actions/workflows/ci.yml/badge.svg)](https://github.com/Kesavan02/cordash/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.x%20%7C%20Dart%203.x-02569B?logo=flutter)](https://flutter.dev)
[![Android Health Connect](https://img.shields.io/badge/Android-Health%20Connect-34A853?logo=android)](https://developer.android.com/health-and-fitness/guides/health-connect)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-FF6F00)](#clean-architecture-blueprint)
[![Target SDK](https://img.shields.io/badge/Android%20SDK-34%20(UpsideDownCake)-blue)](https://developer.android.com)
[![Frame Budget](https://img.shields.io/badge/Frame%20Budget-%E2%89%A4%208.0ms%20%40%2090FPS-00E5FF)](#performance-hud--metrics)

**CorDash** is a high-performance Android health telemetry dashboard built with **Clean Architecture** that interfaces directly with **Android Health Connect** to ingest, process, and render daily **Steps** and rolling **Heart Rate (BPM)** data.

Engineered with zero-allocation `CustomPainter` rendering, Largest-Triangle-Three-Buckets (LTTB) decimation, an active floating **Performance HUD** maintaining $\le 8.0\text{ ms}$ frame budgets ($60\text{–}120\text{ FPS}$), and an instant **`SimSource` Live Demo Engine** for seamless evaluator testing.

---

## Clean Architecture Blueprint

The codebase enforces strict separation of concerns with unidirectional dependency flow (Presentation → Domain ← Data):

```text
cordash/
├── .github/
│   └── workflows/ci.yml             # Automated CI pipeline (formatting, analyze, tests, build)
├── docs/
│   └── performance_profile.md       # DevTools timeline benchmarks & memory analysis
├── integration_test/
│   └── app_simulation_test.dart     # Physical device end-to-end integration test
├── lib/
│   ├── core/
│   │   ├── constants/               # Colors, layout dimensions, decimation limits, SALT
│   │   └── utils/                   # Anti-plagiarism verifier and formatters
│   ├── domain/                      # PURE DART (zero framework dependencies)
│   │   ├── entities/                # StepRecordEntity, HeartRateRecordEntity, PermissionStatusEntity
│   │   ├── repositories/            # HealthRepository & PermissionRepository interfaces
│   │   └── usecases/                # GetStepsStream, GetHeartRateStream, Permissions use cases
│   ├── data/                        # INFRASTRUCTURE & DATA ACCESS
│   │   ├── datasources/             # HealthConnectDataSource (Health Connect SDK + SimSource)
│   │   ├── repositories/            # Concrete HealthRepositoryImpl & PermissionRepositoryImpl
│   │   └── services/                # DeduplicationService & ResamplingService (LTTB)
│   └── presentation/                # USER INTERFACE & STATE MANAGEMENT
│       ├── providers/               # HealthDashboardProvider, PermissionProvider, PerformanceHudProvider
│       ├── screens/                 # DashboardScreen & PermissionsScreen
│       └── widgets/                 # StepsChartPainter, HrChartPainter, ChartContainer, HeaderCards, HUD
└── test/
    ├── golden/                      # Visual pixel-fidelity CustomPainter tests
    └── unit/                        # Deduplication, LTTB decimation, domain, provider, and SALT tests
```

---

## Key Features & Technical Highlights

### 1. High-Performance Zero-Allocation Rendering
* **Elimination of GC Pauses**: Standard Flutter `paint()` allocations cause periodic Garbage Collection (GC) stutters. CorDash reuses pre-allocated static `Paint`, `Path`, and `TextPainter` instances across frames, achieving zero minor GC cycles during telemetry streaming.
* **Targeted `shouldRepaint`**: Compares array sizes, normalized touch coordinates, and latest scalar counts, skipping redundant canvas rasterization passes.

### 2. Weekly 7-Day Steps Activity Chart
* **7 Generous Daily Bars**: Groups activity into a clean, scannable 7-day timeline (`Mon`, `Tue`, `Wed`, `Thu`, `Fri`, `Sat`, `Today`).
* **Empty Day Accuracy**: Days with no steps taken (e.g. rest days or yesterday) are rendered completely empty without misleading dummy placeholders.
* **Live "Today" Growth**: The rightmost bar is dedicated to Today (`#00E5FF`). As you walk or as `SimSource` streams, Today's bar dynamically rises in real time.
* **Interactive Day Scrubbing**: Tap or drag across any bar to inspect exact dates and counts (e.g. `Today: 4,364 steps` or `Wednesday, Sep 16: No steps recorded`).

### 3. Cubic Bezier Heart Rate Spline
* **Smooth Waveform Interpolation**: Computes cubic Bezier control points across chronological heart rate readings.
* **Vertical Linear Shader**: Shaded fill fading gracefully into the `#0C0E17` dark background.
* **Touch Crosshair & Dot Highlight**: Pinpoints exact BPM and timestamp on touch.

### 4. Largest-Triangle-Three-Buckets (LTTB) Decimation
* Real-world heart rate streams produce thousands of points that choke mobile rasterizers.
* CorDash implements the **LTTB algorithm** in [`ResamplingService`](file:///c:/D/personal/cordash/lib/data/services/resampling_service.dart), downsampling up to 5,000 raw readings to 300 visual points in **$< 1.9\text{ ms}$** while strictly preserving telemetry peaks and troughs.

### 5. Android Health Connect & Permissions Rationale
* Configured with `FlutterFragmentActivity` and Android 12/13/14 permissions rationale compatibility:
  * `<action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE" />`
  * Package visibility query `<package android:name="com.google.android.apps.healthdata" />`
* Guarded background polling with try-catch safety to prevent Android foreground caller exceptions.

### 6. One-Tap `SimSource` Live Demo Engine
* Evaluators and interviewers rarely have Google Fit or paired smartwatches on their testing devices.
* Tapping **`START LIVE DEMO STREAM`** (or the top-right `[Sensors]` toggle) begins continuous walking cadence ($2\text{–}8\text{ steps/s}$) and heart rate variance ($68\text{–}88\text{ BPM}$) through the **exact same Clean Architecture pipeline**.
* Tapping **`[STOP SIM]`** immediately purges synthetic state without contaminating real device metrics.

### 7. Real-Time Floating Performance HUD
* Microsecond frame timing listener (`WidgetsBinding.instance.addTimingsCallback`) displaying:
  * **Build Time**: $2.4\text{–}3.9\text{ ms}$ (Target: $\le 8.0\text{ ms}$)
  * **Paint Time**: $1.8\text{–}5.4\text{ ms}$ (Target: $\le 8.0\text{ ms}$)
  * **Frame Rate**: Sustained **90 FPS / 120 FPS** on high-refresh displays.

---

## Anti-Plagiarism & Authenticity Verification

The project embeds a mathematically verifiable, deterministic anti-plagiarism SALT:

* **Package Name**: `com.example.cordash`
* **First Git Commit Hash**: `4b8fea420da7b41d0a7c59535ddfaacfb0bc6e6e`
* **Formula**: `SHA256("${packageName}:${firstGitCommitHash}")` (lowercase hex)
* **Derived SALT**:
  ```text
  53e4cf58eb6634c6149e062b2110da8712b6f9d1403a1d7b735589004348d5c7
  ```
* Embedded in [`AppConstants.antiPlagiarismSalt`](file:///c:/D/personal/cordash/lib/core/constants/app_constants.dart) and Android [`AndroidManifest.xml`](file:///c:/D/personal/cordash/android/app/src/main/AndroidManifest.xml), automatically asserted in [`test/unit/salt_verifier_test.dart`](file:///c:/D/personal/cordash/test/unit/salt_verifier_test.dart).

---

## Automated Test Suite & CI

| Test Suite | File Location | Coverage / Assertions |
| :--- | :--- | :--- |
| **Unit Tests** | `test/unit/` | 18 tests (Deduplication, LTTB decimation, Domain UseCases, Providers, Anti-Plagiarism SALT) |
| **Visual Golden Tests** | `test/golden/` | 4 tests (StepsChartPainter, HeartRateChartPainter, empty states, touch interaction) |
| **Integration Test** | `integration_test/` | End-to-end device execution (Cold start, SimSource live stream, gestures, stop shutdown) |
| **Static Analysis** | Root | `flutter analyze` passes with **0 warnings / 0 errors** |
| **CI Workflow** | `.github/workflows/ci.yml` | Multi-branch CI executing format verification, analyze, tests, and debug build |

---

## Getting Started & Execution Guide

### Prerequisites
* Flutter SDK (3.24+ recommended)
* Android SDK 34 (Android 14) with minimum SDK 26 (Android 8.0 Oreo)

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run All Automated Tests
```bash
# Run unit and visual golden tests
flutter test

# Run device end-to-end integration test
flutter test integration_test/app_simulation_test.dart -d <device_id>
```

### 3. Run the App
```bash
# Debug mode
flutter run

# Profile mode with DevTools timeline tracing
flutter run --profile
```

### 4. Evaluating with `SimSource` Mode
1. Launch CorDash on any phone or emulator.
2. Tap the **"START LIVE DEMO STREAM (SIMSOURCE)"** banner.
3. Observe live step accumulation, real-time BPM variance, and scrub across the interactive charts.
4. Tap **`[STOP SIM]`** to halt simulation and restore clean device state.
