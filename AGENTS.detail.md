# EMF Detector & Wall Cable Scanner - Detailed Technical Specifications (AGENTS.detail.md)

This document provides deep technical details, mathematical formulas, byte specifications, and UI coordinate layouts for key features of the **EMF Detector & Wall Cable Scanner** codebase. Refer to these specifications when modifying math filters, audio synthesis modules, simulation preset generators, or custom canvas graphics.

---

## 1. Vector Mathematics & Calibration Core

To turn a standard smartphone magnetometer into a functional wall scanner, we must isolate localized anomalies (like metal pipes, studs, or active electrical wires) from the natural background magnetic field of the Earth ($\sim 30$-$60\,\mu\text{T}$).

### Formulas

Let the raw, smoothed physical sensor readings be represented as:
$$\vec{R} = \begin{pmatrix} x \\ y \\ z \end{pmatrix}$$

The raw scalar magnitude is the Euclidean norm:
$$||\vec{R}|| = \sqrt{x^2 + y^2 + z^2}$$

### Component-wise Baseline Calibration

When the user taps **CALIBRATE BASELINE**, we capture a snapshot of the ambient magnetic vector at that specific physical location and orientation:
$$\vec{B} = \begin{pmatrix} x_b \\ y_b \\ z_b \end{pmatrix} = \begin{pmatrix} x_{smoothed} \\ y_{smoothed} \\ z_{smoothed} \end{pmatrix}$$

The relative magnetic vector delta represents the net directional deviation from our calibrated zero state:
$$\vec{D} = \vec{R} - \vec{B} = \begin{pmatrix} x - x_b \\ y - y_b \\ z - z_b \end{pmatrix} = \begin{pmatrix} \Delta x \\ \Delta y \\ \Delta z \end{pmatrix}$$

The **True Scalar Delta Magnitude** is then calculated as the vector length of the difference vector:
$$||\vec{D}|| = \sqrt{\Delta x^2 + \Delta y^2 + \Delta z^2}$$

> [!IMPORTANT]
> **Why this matters:** Calculating the magnitude *after* subtracting baseline components allows the scanner to be highly directional and sensitive. Simple scalar subtraction ($||\vec{R}|| - ||\vec{B}||$) fails to isolate directional changes in the magnetic vector when gliding flat along drywall.

### Smoothing Filter
To damp environmental high-frequency noise without introducing human-perceivable lag:
$$x_{smoothed} = x_{previous} + \alpha \times (x_{raw} - x_{previous})$$
Where:
* **$\alpha = 0.22$** (exponential moving average coefficient)
* Frequency = **$30\,\text{Hz}$** (33ms sampling interval)

---

## 2. Dynamic Geiger Auditory WAV Synthesis

To bypass the need for bundling static sound files (which expands application bundle size and introduces loading latency), the app dynamically synthesizes a custom **Geiger-counter tick sound** as an in-memory byte array and writes it as a temporary `.wav` file on startup.

### WAV Header Structure (44 Bytes PCM)

The synthesized file is formatted as an **16-bit Mono PCM WAV** with a sample rate of **$44100\,\text{Hz}$**. Duration is exactly **$200\,\text{ms}$** (yielding **$8820$ samples**).

| Offset (Bytes) | Field Name | Hex / Value (Little Endian) | Description |
| :--- | :--- | :--- | :--- |
| **0 - 3** | ChunkID | `52 49 46 46` ("RIFF") | RIFF container header |
| **4 - 7** | ChunkSize | `14 45 00 00` (17676 - 8 = 17668) | File size minus 8 bytes |
| **8 - 11** | Format | `57 41 56 45` ("WAVE") | WAV format identifier |
| **12 - 15** | Subchunk1ID | `66 6D 74 20` ("fmt ") | Format subchunk header |
| **16 - 19** | Subchunk1Size | `10 00 00 00` (16) | Size of fmt subchunk |
| **20 - 21** | AudioFormat | `01 00` (1) | PCM linear format |
| **22 - 23** | NumChannels | `01 00` (1) | Mono channel count |
| **24 - 27** | SampleRate | `44 AC 00 00` (44100) | Sampling rate in Hz |
| **28 - 31** | ByteRate | `88 58 01 00` (88200) | Bytes per second (SampleRate * channels * bits/8) |
| **32 - 33** | BlockAlign | `02 00` (2) | Bytes per sample slice (channels * bits/8) |
| **34 - 35** | BitsPerSample | `10 00` (16) | 16-bit signed PCM |
| **36 - 39** | Subchunk2ID | `64 61 74 61` ("data") | Data subchunk header |
| **40 - 43** | Subchunk2Size | `E8 44 00 00` (17640) | Number of audio sample bytes |

### Audio Waveform Synthesis Algorithm

The click sound is synthesized by multiplying a high-frequency sine wave with a steep exponential decay envelope to yield a organic "Geiger pop":
$$y(t) = 32767 \times \exp(-t \times 220.0) \times \sin(2\pi \times 1800.0 \times t)$$
Where:
* **$32767$**: The peak amplitude for signed 16-bit PCM.
* **$\exp(-t \times 220.0)$**: Fast exponential decay envelope giving the sound its percussive "pop".
* **$\sin(2\pi \times 1800.0 \times t)$**: High-frequency carrier wave ($1.8\,\text{kHz}$) giving the tick a metallic bite.

---

## 3. Interactive Simulation Engine Presets

For platforms lacking physical magnetometer hardware (e.g. Windows PC Desktop, Android Emulators), the `SensorService` falling back to a virtual mock stream running at **$30\,\text{Hz}$**.

### Ambient Earth Base Offset
All simulations are overlaid on a realistic baseline representing standard Earth magnetism vectors in microteslas:
$$\vec{B}_{earth} = \begin{pmatrix} X_{base} \\ Y_{base} \\ Z_{base} \end{pmatrix} = \begin{pmatrix} 40.0 \\ -15.0 \\ -20.0 \end{pmatrix}$$

### Presets Specs

1. **`SimulationPreset.none` (Earth Normal)**:
   - Yields baseline coordinates overlaid with standard sensor white-noise jitter ($\pm 0.6\,\mu\text{T}$).
2. **`SimulationPreset.mainsCable` (Mains AC Wire Proximity)**:
   - Mimics active alternating current inside a wall by adding an oscillating sine wave overlay:
     $$acWave(t) = 85.0 \times \sin(t \times 12.0)$$
     $$\vec{R}_{sim} = \vec{B}_{earth} + \begin{pmatrix} acWave(t) \\ 0.5 \times acWave(t) \\ 0.2 \times acWave(t) \end{pmatrix}$$
3. **`SimulationPreset.strongMagnet` (Neodymium Magnet Proximity)**:
   - Simulates permanent magnet field saturation by injecting a massive, constant DC offset vector:
     $$\vec{R}_{sim} = \vec{B}_{earth} + \begin{pmatrix} 180.0 \\ -80.0 \\ 120.0 \end{pmatrix}$$
4. **`SimulationPreset.ambientNoise` (Walk Drift)**:
   - Simulates walking past high-power electrical boxes or panels by applying a slow multi-frequency vector drift:
     $$\vec{R}_{sim} = \vec{B}_{earth} + \begin{pmatrix} 15.0 \times \sin(t \times 0.5) \\ 10.0 \times \cos(t \times 0.3) \\ 8.0 \times \sin(t \times 0.2) \end{pmatrix}$$

---

## 4. Reusable Custom Widgets Guide

To preserve high performance and ensure cyberpunk visual layout consistency, developers must maintain these specific canvas drawing rules:

### CircularGauge (`lib/ui/widgets/circular_gauge.dart`)
* **Geometry**: Sweeps a $270.0^\circ$ radial arc starting from $135.0^\circ$ (bottom-left) to $405.0^\circ$ (bottom-right).
* **Glow Layer**: Drawn with standard `Paint.imageFilter = ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0)` targeting the sweep rectangle, rendering neon cyber-glows on GPU.
* **Ticks**: Drawn iteratively inside the sweep angle at $9.0^\circ$ divisions (31 total tick notches). Active ticks map to a SweepGradient representing safety zones (Cyan -> Green -> Orange -> Cyberpunk Warning Pink).

### OscilloscopeChart (`lib/ui/widgets/oscilloscope_chart.dart`)
* **CRT Screen**: Deep obsidian blue background (`#0F1019`) with a moving coordinate mesh drawn via `_drawGrid()` using $0.03$ alpha Cyan lines.
* **Smooth Spline Pathing**: Uses a series of quadratic Bézier curve interpolation paths:
  ```dart
  path.quadraticBezierTo(p1.dx, p1.dy, xc, yc);
  ```
  This creates fluid liquid transitions for wave peaks instead of coarse polygonal segments.
* **Alert Marker**: A dotted horizontal warning line drawn using a custom dashed path loop that tracks the safety threshold value relative to the vertical chart axis.

---

## 5. Responsive UI Layout & Text Wrapping Rules

To prevent rendering overflows and ensure all views scale gracefully down to very narrow smartphone screens (e.g. 320px or less):

### The Flutter Text Wrap Paradox
In Flutter, layout is governed by the rule: **Constraints go down, sizes go up, and parent sets position.**
By default, horizontal layout widgets like `Row` offer their children **infinite** horizontal space on their layout axis. Because a `Text` widget has no internal knowledge of screen boundaries unless those boundaries are explicitly *imposed* on it, a raw `Text` inside a `Row` will attempt to render on a single continuous line, stretching indefinitely and causing an overflow exception on small screens.

### Mandatory Directives for AI Agents
1. **Force Constraints Inside Rows**: Always wrap any potentially long `Text` inside a `Row` with an `Expanded` or `Flexible` widget. This forces the layout engine to calculate remaining screen width, imposing constraints that compel the `Text` to wrap gracefully.
2. **Use Wrap over Row for Spaced Flow**: For headers, action options, and lists of badges/controls (e.g. a panel of toggle buttons), prefer using a `Wrap` widget instead of a `Row`. Set standard `spacing` and `runSpacing` properties to let controls drop to the next line dynamically:
   ```dart
   Wrap(
     spacing: 8.0,
     runSpacing: 12.0,
     alignment: WrapAlignment.spaceEvenly,
     children: [ ... ],
   )
   ```
3. **Isolate Button Icons in Multi-Row / Small Viewports**: To ensure button text has maximum space to wrap symmetrically without getting clipped or misaligned by inline graphic elements:
   - Never embed emojis or raw icon code directly inside a button `Text` string.
   - Use a `Stack` or structured bounding box to pin button icons to the absolute edge (e.g. `left: 16`), combined with `Padding(horizontal: 46.0)` on the centered `Text` child to allow symmetric multi-line text wrapping without overlapping.

