# Material 3 Expressive (M3E) Settings Architecture & Design System

## 1. Executive Summary & Philosophy

As Obtainium+ has grown with advanced features (ShizukuPlus integration, multi-user profile detection, usage access tracking, automated installation conflict handling, and unmetered online database lookups), the settings space has accumulated duplicate configuration toggles and visual clutter.

This architecture document establishes the definitive **Material 3 Expressive (M3E)** design system, information architecture (IA), haptics hierarchy, and motion guidelines for Obtainium+.

### Core Tenets
1. **The "Single Authoritative Home" Rule**: No setting should ever be rendered or controlled in more than one place. Related sections cross-reference each other through lightweight connected chips and navigation pills, never duplicate switches.
2. **Scannability via M3E Visual Chunking**: Users should be able to scan an entire section in under two seconds. We achieve this with expressive squircle cards, high-contrast semantic icon badges, clear primary vs secondary typography, and concise subtitle summaries.
3. **Zero-Jumpiness Motion & Spatial Continuity**: Layout shifts must be fluid and predictable. Height changes animate smoothly via cubic curves, tabs cross-fade with shared-axis spatial momentum, and page transitions use forward/backward scaling rather than sudden route jumps.
4. **Immediate Tactile Feedback**: Touch interactions feel physical and alive. Switches, sliders, segment selectors, and sheets produce instant, distinctive haptic patterns matching Android 14/15/16 system conventions.

---

## 2. Information Architecture (Categorical Taxonomy)

Settings are organized into **5 core top-level categories**, each mapped to an authoritative domain without overlap:

```
Settings Hierarchy
├── 🎨 Appearance & Personalization (Tab 0)
│   ├── Visual Theme & Monet Palette
│   ├── App Tile & Grid Styling
│   ├── Navigation & Density Layout
│   └── Motion, Glassmorphism & Corner Radii
│
├── ⚡ Updates & Installation (Tab 1)
│   ├── Update Checking Schedule & Concurrency
│   ├── Installation Engine (Shizuku, Root, Session, System)
│   └── Verification, Downgrade & Conflict Prevention
│
├── 🔔 Notifications & Alerts (Tab 2)
│   ├── Background Update Channels & Badges
│   ├── Progress & Completion Banners
│   └── Error & Rate-Limit Diagnostics
│
├── 🕹️ App Behavior & Gestures (Tab 3)
│   ├── Swipe Gestures & Sandbox Simulator
│   ├── App Launch & Usage Recency Access
│   └── Library Management & Auto-Uninstall
│
└── 🛠️ Advanced & Diagnostics (Tab 4)
    ├── Developer Sandbox & FDFE Protocol Inspector
    ├── Multi-User & Work Profile Diagnostics
    ├── Network, VPN & Online App Registries
    └── Cache Repair, Export & Reset
```

---

## 3. Deduplication Matrix (Before vs. After)

| Feature / Setting | Legacy Multi-Location Duplication | Authoritative Single Home |
| :--- | :--- | :--- |
| **Shizuku Installation & Privileged Shell** | Appeared in `UpdateSettingsSection`, `InstallationSection`, and `TroubleshootingSection`. | **Tab 1: Updates & Installation → Installation Engine** (`InstallationSection`). `SettingsHeroOverview` and `Troubleshooting` display only status badges that navigate directly to this section. |
| **Background Update Workaround** | Duplicated across `UpdateSettingsSection` and `AppBehaviorSection`. | **Tab 1: Updates & Installation → Update Schedule & Concurrency** (`UpdateSettingsSection`). |
| **Default App Details Tab** | Duplicated in `AppsViewSettingsSection` and `ThemeSettingsSection`. | **Tab 0: Appearance → App Tile Styling** (`AppsViewSettingsSection`). |
| **Usage Access Permission & Metrics** | Appeared in `DeveloperSettingsPage`, `AppBehaviorSection`, and `DeviceOptimizationSheet`. | **Tab 3: App Behavior & Gestures → Usage Recency Access** (`UsageAccessCard`). Connected shortcut chips point here from other pages. |
| **Compact Settings Density** | Toggled in app bar, `AppsViewSettingsSection`, and `ThemeSettingsSection`. | **App Bar Action Button** with instant sync to `PlusSettingsProvider.plusUseCompactSettings`. Removed duplicate toggles in body sections. |

---

## 4. Motion, Gestures & Spatial Transitions

### Material Shared Axis Model
- **Forward Drill-Down (Shared Axis Z)**:
  - Transition from Settings main list into a `SettingsSubpage` or detail screen:
  - Entering page scales from `0.94` to `1.0` with `Curves.easeOutCubic` (280ms) and fades in from `0.0` to `1.0`.
  - Exiting page scales from `1.0` to `1.06` with subtle fade-out.
- **Lateral Section Switching (Shared Axis X)**:
  - Switching between sibling subpages or top-level tabs:
  - Horizontal slide offset of `±4%` screen width paired with cross-fade (240ms `Easing.emphasizedDecelerate`).
- **Modal Sheets & Overlays (Shared Axis Y)**:
  - Bottom sheets (e.g. `AppDescriptionCard`, `DeviceOptimizationSheet`, `MultiUserDiagnosticSheet`) use vertical slide with spring damping, downward swipe dismissibility, and a tactile drag handle.

### Eliminating Layout Jumpiness
- **Smooth Container Height**: When toggles reveal secondary controls (such as expanding custom interval pickers or Shizuku options), wrap the content in `AnimatedSize` with `alignment: Alignment.topCenter` and duration `240ms` (`Curves.easeOutCubic`). This prevents abrupt list jumps.
- **Stable Scroll Anchoring**: Pinned tab headers and category bars retain fixed metric heights regardless of search query state, preventing viewport stutter.

---

## 5. Haptics Hierarchy Specification

Obtainium+ uses a 4-tier tactile feedback hierarchy aligned with Android's Rich Haptics API:

```
Tactile Feedback Hierarchy
├── Tier 1: Selection Click (Crisp / Micro)
│   ├── Navigation tab selection
│   ├── Filter & search chip taps
│   └── Radio/segment button switching
│
├── Tier 2: Toggle Flip (Subtle Spring)
│   ├── Switch ON: `AppHaptics.toggleOn()`
│   └── Switch OFF: `AppHaptics.toggleOff()`
│
├── Tier 3: Slider Detent & Swipe Threshold (Mechanical Tick)
│   ├── Discrete slider step changes (e.g. concurrency 1 -> 2 -> 4 -> 6 -> 8)
│   └── Swipe gesture 38% trigger activation
│
└── Tier 4: Elevated Action / Heavy Impact (Deep Pulse)
    ├── 1-Tap Shizuku elevated grant
    ├── Root permission request
    └── Factory reset / cache clearance
```

---

## 6. Visual Component Standards (M3E Tokens)

### 1. Expressive Settings Group (`ExpressiveSettingsGroup`)
- **Container**: `surfaceContainerHigh` (light) / `surfaceContainer` (dark).
- **Border**: 1dp `outlineVariant` with 30% alpha.
- **Corner Radius**: Global squircle token (`CardMetrics.card(radius, expressive: true)`).
- **Spacing**: 14dp vertical gap between groups, 16dp horizontal padding.

### 2. Settings Feature Tile (`SettingsFeatureToggle`)
- **Icon Container**: 38×38dp squircle badge with `primaryContainer` / `secondaryContainer` fill.
- **Title**: `titleSmall` / `labelLarge` with bold weight (`FontWeight.w600`).
- **Subtitle**: `bodySmall` with `onSurfaceVariant` color, max 2 lines.
- **Interactive Feedback**: Wrapped in `ScaleTouchWrapper` with `scaleDownFactor: 0.985` and instant down-tick.
