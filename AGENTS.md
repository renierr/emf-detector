# AI Developer Guidelines & Project Playbook (AGENTS.md)

Welcome, AI Developer! This playbook provides the technical rules, architectural guardrails, and design aesthetics for maintaining and scaling the **EMF Detector & Wall Cable Scanner** codebase.

For detailed math vector formulas, synthesized WAV headers, stream simulation values, and reusable widgets specifications, refer to [AGENTS.detail.md](AGENTS.detail.md).

---

## Priority Model

- `ALWAYS`: Hard constraints. Do not violate.
- `PREFER`: Default behavior. Use unless there is a clear reason not to.

---

## ALWAYS

- **Git Write Consent**: Never run git write operations (`git add`, `git commit`, `git push`) without fresh explicit approval for each write command.
- Never mention AI agents, co-authorship, or AI generation in commit messages or code.
- **Resilience to Rejected Commands**: If a user rejects or stops a command execution, continue the task and provide the alternative results or plan. A rejected command must not abort the overall execution.
- **State Management & Data Flow**: Always channel sensor configurations, calibration offsets, alert states, and history logs through `DetectorState` in `lib/state/detector_state.dart`. Never update local state variables in views for persistent data.
- **Smooth Custom Painters**: High-frequency visual updates (e.g. radial dials, oscilloscope lines) must be handled by `CustomPainter` canvases with hardware acceleration. Do not use standard widgets or layout rebuilds for frequent visual updates.
- **Mock Simulation Fallbacks**: Always maintain the interactive **Simulated Sensor Mode** for desktop execution (Windows) or emulators. The app must detect silent sensors and fall back to simulation to keep the UI fully testable.
- **Small Screen Fitting**: Always use responsive layouts (like `Wrap` instead of horizontal `Row` for actions, and scrollable/grid metrics) in dashboard cards and dialog panels to prevent overflow on mobile.
- **Prevent Duplicated UI/Painter Code**: Extract custom visual structures, grid drawers, neon gradients, or warning alerts to `lib/ui/widgets/` immediately. Never copy-paste presentation logic across views.
- **No Dialog Snackbars**: Never show `ScaffoldMessenger` snackbars inside modal dialogs (as they render behind the active dialog). Use custom center-placed alert overlays or inline widgets.
- **Strict Input Validation**: Enforce numeric restrictions on any numeric input fields (like threshold settings) using `FilteringTextInputFormatter.digitsOnly` to prevent parsing crashes.

---

## PREFER

- Keep answers extremely short and concise.
- Use English for code, comments, and docs.
- Use explicit return types for methods.
- Avoid inline hardcoded visual colors. Reference standard colors from the app's `ThemeData` to ensure cyberpunk design system consistency.
- Bind UI screens to state using modern `ListenableBuilder` or modern `context.select()` syntax to optimize element trees and rebuild footprints.
- Log errors with clear service or page context prefixes to make debugging easy.
- **Private Widgets over Helpers**: Prefer declaring private `StatelessWidget` classes instead of helper methods returning `Widget` to optimize element tree lifecycles and rebuilds.
- **Const Constructors**: Prefer using `const` constructors for widgets and in `build()` methods where possible to reduce rebuilds.
- **Bézier Curves over Segment Lines**: Prefer smooth quadratic/cubic Bézier curve pathing for real-time oscilloscope waves to maintain high premium graphical quality.
- **Context-Driven Date Formats**: Prefer retrieving device-driven locale tags to format dates (such as scanner logs) dynamically rather than hardcoding date layouts: `Localizations.localeOf(context).toLanguageTag()`.

---

## Core Guardrails

### 1. State Management & UI Binding
- Standard: `ChangeNotifier` (`DetectorState`).
- Stream controller manages hardware and simulation input streams.
- Ensure UI automatically rebuilds by binding via standard `ListenableBuilder` listeners.

### 2. Physical & Virtual Sensors
- Service: `SensorService` detects actual hardware availability. On failure or timeout, it automatically starts a virtual generator timer (33ms interval) yielding values matching preset environments (Mains AC Wire, Neodymium Magnet, Walk Drift).

### 3. Acoustic Geiger Synthesis
- Service: `AudioService` synthesizes a 20ms sine wave click at 1800Hz with steep exponential decay directly to a temporary WAV file, avoiding manual asset configuration. The click is re-triggered at intervals matching EMF delta strength.

### 4. Cyberpunk Styling System
- Color schemes are absolute Dark Mode (`#07080D` scaffold) with Neon Cyan (`#00F2FE`), Emerald (`#00FF87`), warning Amber (`#FFD200`), and alert Cyberpunk Red/Pink (`#FF0055`).
- Font readouts should utilize *Orbitron* (digital style) and UI text *Outfit* or *Inter*.

---

## Package Dependencies Reference

| Package | Purpose |
|---|---|
| `sensors_plus` | Accesses physical hardware Magnetometer |
| `wakelock_plus` | Keeps device screen awake during scanning operations |
| `google_fonts` | Cylindrically fetches digital Orbitron and Outfit fonts |
| `audioplayers` | Low-latency audio playback for the simulated Geiger ticks |

---

## Verification Procedures

*Note: Formatting, static analysis, and testing are strictly required ONLY when Dart/source code files are changed. Do NOT run them for changes that only affect markdown documentation, images, static assets, or settings. Run test suites and analyzers only when really needed to verify core code modifications.*

1. **Formatting**: `dart format ./lib`
2. **Analysis**: `flutter analyze`
