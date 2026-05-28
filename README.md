# ⚡ EMF Detector & Wall Cable Scanner

A professional-grade, visually astonishing **Electromagnetic Field (EMF) Detector & Wall Cable Scanner** built with Flutter. Leverage your mobile device's magnetic sensors to pinpoint hidden electrical currents, power cables, metal pipes, and magnets inside walls, presenting readings in a premium, real-time cyberpunk dashboard.

---

## 📱 For End Users

### What is the EMF Detector?
All electrical cables carrying current and metallic conduits create localized electromagnetic anomalies. Your smartphone is equipped with a highly sensitive **magnetometer** (normally used for the digital compass). This app harnesses that raw sensor, processes it through advanced low-pass filters, and turns it into a high-precision wall scanner and field locator.

### Key Features
* **Neon Circular Gauge**: Displays current electromagnetic force in microteslas ($\mu\text{T}$) with a real-time glowing responsive dial.
* **Ambient Calibration (Zero-Point)**: The Earth has a natural magnetic field of $\sim 30$-$60\,\mu\text{T}$ which is always present. Tap **Calibrate** in open space to set it as a zero baseline, making it incredibly simple to isolate small local fields (like cables and pipes behind drywall!).
* **3-Axis Vector Split**: Detailed visual bars decompose fields into $X$ (left/right), $Y$ (up/down), and $Z$ (forward/back) components, indicating exactly where the source is.
* **Scrolling Oscilloscope Graph**: A fluid real-time history line chart that behaves like a scanning oscilloscope, letting you see magnetic shifts as you move across a surface.
* **Geiger Auditory Feedback**: An acoustic warning system that beeps faster as you get closer to a magnetic anomaly.
* **Tactile Haptic Radar**: Haptic vibrations on Android devices that pulse with increasing frequency near wires, providing blind tactile feedback when scanning.
* **Simulated Sensor Mode (Desktop/Fallback)**: Lacking a magnetic sensor on Windows or in an emulator? The app automatically activates an interactive simulation dashboard with sliders and presets (e.g., "Mains Power Cable in Drywall", "Neodymium Magnet") so you can test all features.

### 🔍 How to Scan Walls for Cables
1. **Calibrate First**: Hold your phone in open air, away from computer screens, magnets, or walls. Tap **CALIBRATE BASELINE**. The reading should drop to $\approx 0\,\mu\text{T}$.
2. **Configure Indicators**: Turn on **Sound** or **Haptic** feedback if you want auditory/tactile guides.
3. **Scan Slowly**: Place the back of your phone flat against the wall and glide it slowly in a grid pattern.
4. **Identify Anomalies**: When passing over an active AC electrical line or metal stud, the gauge will spike into the **Orange/Red warning zones**, the scrolling oscilloscope will show a sharp peak, and the Geiger beep will chirp rapidly.

> [!CAUTION]
> **Safety Warning:** This app is a highly responsive software-based scanner utilizing consumer-grade magnetometer hardware. While excellent for locating hidden lines and studs, always exercise caution and consult professional blueprints or dedicated voltage detectors before drilling into walls.

---

## 🛠️ For Developers

This project is built using Flutter and Dart, targeting **Android** and **Windows** platforms.

### Project Organization
The project package identifier is set to `de.renier.emf_detector` under the `de.renier` organization base.

```
lib/
├── models/          # Data structures for EMF readings and calibration baseline
├── services/        # Hardware sensor streams and mock simulation providers
├── state/           # State management via ChangeNotifier (UI states, baseline, audio trigger)
├── ui/              # User interface
│   ├── screens/     # Dashboard and scan views
│   └── widgets/     # Custom painters for Neon Gauge and Oscilloscope Graph
└── main.dart        # Application entry point and theme definitions
```

### Core Architecture
To maintain high performance and buttery-smooth 60+ FPS visualizations, the app avoids heavy UI rebuilding:
* **Custom Painters**: The glowing Neon Circular Gauge and the Scrolling Oscilloscope Graph are drawn directly onto a custom canvas using hardware-accelerated drawing operations.
* **Unified Sensor Service**: `SensorService` detects whether hardware sensors are present. On Windows or in emulators, it falls back to a simulated stream controllable via developer widgets in the UI.

### Getting Started

#### Prerequisites
* Flutter SDK (3.12.0+ recommended)
* Dart SDK (3.0.0+ recommended)
* VS Code or Android Studio
* Android device (for real magnetometer testing) or Windows PC (runs in simulated developer mode)

#### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone <repository_url>
   cd emf-detector
   ```

2. **Fetch dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**
   * **To run on your connected Android device:**
     ```bash
     flutter run -d android
     ```
   * **To run on Windows Desktop (runs in Simulator Mode):**
     ```bash
     flutter run -d windows
     ```

### Core Dependencies
* `sensors_plus`: For accessing mobile magnetometer sensors.
* `wakelock_plus`: Prevents screen sleep while actively scanning walls.
* `google_fonts`: Loads high-tech cyberpunk font *Orbitron* and *Outfit* dynamically.
* `audioplayers`: Handles low-latency Geiger ticks.

---

## 📄 License
This project is proprietary and intended for development.
