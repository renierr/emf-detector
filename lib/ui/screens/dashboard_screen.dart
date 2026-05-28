import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../models/emf_reading.dart';
import '../../services/sensor_service.dart';
import '../../state/detector_state.dart';
import '../widgets/circular_gauge.dart';
import '../widgets/oscilloscope_chart.dart';
import '../widgets/axis_bar.dart';

class DashboardScreen extends StatefulWidget {
  final DetectorState state;

  const DashboardScreen({
    super.key,
    required this.state,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _wakeLockActive = false;

  @override
  void initState() {
    super.initState();
    _checkWakeLock();
  }

  void _checkWakeLock() async {
    final active = await WakelockPlus.enabled;
    setState(() {
      _wakeLockActive = active;
    });
  }

  void _toggleWakeLock() async {
    final target = !_wakeLockActive;
    if (target) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
    setState(() {
      _wakeLockActive = target;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, child) {
        final state = widget.state;
        final current = state.currentReading ?? EmfReading.fromRaw(0, 0, 0);
        final isWarning = state.isScanning && current.deltaMagnitude >= state.warningThreshold;

        return Scaffold(
          backgroundColor: const Color(0xFF07080D), // Ultra-deep space black
          body: Stack(
            children: [
              // High-tech top ambient gradient glow
              Positioned(
                top: -150,
                left: -50,
                right: -50,
                height: 350,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 0.8,
                      colors: isWarning
                          ? [
                              const Color(0xFFFF0055).withValues(alpha: 0.18),
                              const Color(0xFFFF0055).withValues(alpha: 0.0),
                            ]
                          : [
                              const Color(0xFF00F2FE).withValues(alpha: 0.12),
                              const Color(0xFF00F2FE).withValues(alpha: 0.0),
                            ],
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Section
                      _buildHeader(state),
                      const SizedBox(height: 24),

                      // Warning alert banner (only displayed on spikes)
                      if (isWarning) _buildCableDetectedBanner(),

                      // Primary Gauge Panel
                      Center(
                        child: CircularGauge(
                          value: current.deltaMagnitude,
                          threshold: state.warningThreshold,
                          isScanning: state.isScanning,
                          maxExpected: 160.0,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Calibration Panel
                      _buildCalibrationRow(state, current),
                      const SizedBox(height: 24),

                      // 3-Axis Vector Breakdown
                      _buildVectorCard(state, current),
                      const SizedBox(height: 20),

                      // Real-time scrolling chart
                      _buildOscilloscopeHeader(),
                      const SizedBox(height: 8),
                      OscilloscopeChart(
                        history: state.history,
                        threshold: state.warningThreshold,
                        isScanning: state.isScanning,
                        maxVal: 160.0,
                      ),
                      const SizedBox(height: 24),

                      // Controls & Feedback toggles
                      _buildScannerControlsCard(state),
                      const SizedBox(height: 24),

                      // Developer Mode Dock (Mock Simulators)
                      _buildSimulatorSettingsCard(state),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(DetectorState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '⚡ EMF SCANNER',
                  style: GoogleFonts.orbitron(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F2FE).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PRO',
                    style: GoogleFonts.orbitron(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00F2FE),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'WALL CURRENT & CURRENT LOCATOR',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),

        // Device hardware sensor / simulation status badge
        GestureDetector(
          onTap: () {
            // Allows toggle simulation mode manually by tapping the badge
            state.setSimulationMode(!state.isSimulationActive);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: state.isSimulationActive
                  ? const Color(0xFFFFD200).withValues(alpha: 0.08)
                  : const Color(0xFF00FF87).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: state.isSimulationActive
                    ? const Color(0xFFFFD200).withValues(alpha: 0.4)
                    : const Color(0xFF00FF87).withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.isSimulationActive
                        ? const Color(0xFFFFD200)
                        : const Color(0xFF00FF87),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  state.isSimulationActive ? 'SIMULATOR' : 'HARDWARE SENSOR',
                  style: GoogleFonts.orbitron(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: state.isSimulationActive
                        ? const Color(0xFFFFD200)
                        : const Color(0xFF00FF87),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCableDetectedBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF0055).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF0055).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFF0055),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CABLE / METAL DETECTED',
                  style: GoogleFonts.orbitron(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF0055),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Strong local magnetic field anomaly detected inside wall.',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationRow(DetectorState state, EmfReading current) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Calibrate Button
            ElevatedButton.icon(
              onPressed: state.isScanning ? state.calibrateBaseline : null,
              icon: const Icon(Icons.gps_fixed, size: 14),
              label: Text(
                'CALIBRATE BASELINE',
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: const Color(0xFF07080D),
                backgroundColor: const Color(0xFF00FF87),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.04),
                disabledForegroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Reset Button
            OutlinedButton(
              onPressed: state.isScanning && state.isCalibrated ? state.resetBaseline : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.grey[600],
                side: BorderSide(
                  color: state.isScanning && state.isCalibrated 
                      ? Colors.white.withValues(alpha: 0.3) 
                      : Colors.white.withValues(alpha: 0.06),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'RESET',
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          state.isCalibrated
              ? 'Zero-offset applied: X:${state.baselineX.toStringAsFixed(1)} Y:${state.baselineY.toStringAsFixed(1)} Z:${state.baselineZ.toStringAsFixed(1)}'
              : 'Calibrate in open space to filter ambient Earth magnetic fields.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: state.isCalibrated ? const Color(0xFF00FF87).withValues(alpha: 0.8) : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildVectorCard(DetectorState state, EmfReading current) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '3-AXIS VECTOR READOUT',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.grey[400],
                ),
              ),
              Text(
                state.isScanning ? 'LIVE SENSORS' : 'PAUSED',
                style: GoogleFonts.orbitron(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: state.isScanning ? const Color(0xFF00F2FE) : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AxisBar(
            label: 'X',
            value: state.isScanning ? current.deltaX : 0.0,
            activeColor: const Color(0xFF00F2FE), // Cyan
            isScanning: state.isScanning,
          ),
          AxisBar(
            label: 'Y',
            value: state.isScanning ? current.deltaY : 0.0,
            activeColor: const Color(0xFF00FF87), // Emerald
            isScanning: state.isScanning,
          ),
          AxisBar(
            label: 'Z',
            value: state.isScanning ? current.deltaZ : 0.0,
            activeColor: const Color(0xFFFF0055), // Pink/Red
            isScanning: state.isScanning,
          ),
        ],
      ),
    );
  }

  Widget _buildOscilloscopeHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'SCROLLING OSCILLOSCOPE',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.grey[400],
          ),
        ),
        Text(
          'TIME DOMAIN HISTORY',
          style: GoogleFonts.orbitron(
            fontSize: 9,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildScannerControlsCard(DetectorState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main scan toggle + sound/haptics selectors
          Row(
            children: [
              // Main Action Button
              Expanded(
                child: InkWell(
                  onTap: state.toggleScanning,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: state.isScanning
                            ? [const Color(0xFFFF0055), const Color(0xFF9D50BB)]
                            : [const Color(0xFF00F2FE), const Color(0xFF4FACFE)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: (state.isScanning ? const Color(0xFFFF0055) : const Color(0xFF00F2FE)).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        state.isScanning ? '⚡ STOP SCANNING' : '🔍 START SCANNING',
                        style: GoogleFonts.orbitron(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Toggles and sliders row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Sound Toggle
              _buildFeedbackButton(
                icon: state.soundEnabled ? Icons.volume_up : Icons.volume_off,
                label: 'AUDIO TICK',
                active: state.soundEnabled,
                onTap: state.toggleSound,
              ),

              // Haptic Toggle
              _buildFeedbackButton(
                icon: state.hapticsEnabled ? Icons.vibration : Icons.mobile_off,
                label: 'HAPTICS',
                active: state.hapticsEnabled,
                onTap: state.toggleHaptics,
              ),

              // Wake lock toggle
              _buildFeedbackButton(
                icon: _wakeLockActive ? Icons.screen_lock_rotation : Icons.screen_rotation,
                label: 'SCREEN ON',
                active: _wakeLockActive,
                onTap: _toggleWakeLock,
              ),
            ],
          ),
          
          const Divider(color: Colors.white10, height: 28),

          // Alert threshold slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CABLE TRIGGER THRESHOLD',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.grey[400],
                    ),
                  ),
                  Text(
                    '${state.warningThreshold.round()} µT',
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFD200),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFFFFD200),
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                  thumbColor: const Color(0xFFFFD200),
                  overlayColor: const Color(0xFFFFD200).withValues(alpha: 0.12),
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: state.warningThreshold,
                  min: 15.0,
                  max: 120.0,
                  onChanged: state.setWarningThreshold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: active ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: active ? const Color(0xFF00FF87) : Colors.grey[500],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: active ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulatorSettingsCard(DetectorState state) {
    if (!state.isSimulationActive) {
      // Don't clutter UI on actual phones where sensor is active (but allow manual simulator overrides by turning it on)
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.01),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: TextButton.icon(
            onPressed: () => state.setSimulationMode(true),
            icon: const Icon(Icons.science_outlined, size: 14),
            label: Text(
              'OPEN VIRTUAL SENSOR TOOLBOX (DEVELOPER)',
              style: GoogleFonts.orbitron(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[500],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14120E), // Slightly warm developer brown-black
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD200).withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🛠️ DEVELOPER SIMULATION LAB',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: const Color(0xFFFFD200),
                ),
              ),
              GestureDetector(
                onTap: () => state.setSimulationMode(false),
                child: Text(
                  'EXIT SIM',
                  style: GoogleFonts.orbitron(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Simulation Presets Toggle
          Text(
            'SELECT FIELD SCENARIO PRESET',
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildPresetChip(state, SimulationPreset.none, 'Earth Normal'),
              _buildPresetChip(state, SimulationPreset.mainsCable, 'Mains Wire (AC)'),
              _buildPresetChip(state, SimulationPreset.strongMagnet, 'Magnet Proximity'),
              _buildPresetChip(state, SimulationPreset.ambientNoise, 'Walk Drift (Drift)'),
            ],
          ),
          
          const Divider(color: Colors.white10, height: 24),
          
          // Manual Slider Overrides
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MANUAL X, Y, Z VECTOR ADJUSTMENTS',
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                ),
              ),
              if (state.currentPreset == SimulationPreset.none)
                Text(
                  'MANUAL ACTIVE',
                  style: GoogleFonts.orbitron(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00FF87),
                  ),
                )
            ],
          ),
          const SizedBox(height: 6),
          _buildManualVectorSlider(
            label: 'X Offset',
            value: state.currentReading?.x ?? 0.0,
            onChanged: (val) {
              state.setSimulationPreset(SimulationPreset.none);
              state.setManualSimulationValues(
                val, 
                state.currentReading?.y ?? 0.0, 
                state.currentReading?.z ?? 0.0
              );
            },
          ),
          _buildManualVectorSlider(
            label: 'Y Offset',
            value: state.currentReading?.y ?? 0.0,
            onChanged: (val) {
              state.setSimulationPreset(SimulationPreset.none);
              state.setManualSimulationValues(
                state.currentReading?.x ?? 0.0, 
                val, 
                state.currentReading?.z ?? 0.0
              );
            },
          ),
          _buildManualVectorSlider(
            label: 'Z Offset',
            value: state.currentReading?.z ?? 0.0,
            onChanged: (val) {
              state.setSimulationPreset(SimulationPreset.none);
              state.setManualSimulationValues(
                state.currentReading?.x ?? 0.0, 
                state.currentReading?.y ?? 0.0, 
                val
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(
    DetectorState state, 
    SimulationPreset preset, 
    String label
  ) {
    final isSelected = state.currentPreset == preset;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isSelected ? const Color(0xFF07080D) : Colors.grey[300],
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFFFFD200),
      backgroundColor: Colors.white.withValues(alpha: 0.04),
      side: BorderSide(
        color: isSelected ? const Color(0xFFFFD200) : Colors.white.withValues(alpha: 0.08),
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onSelected: (selected) {
        if (selected) {
          state.setSimulationPreset(preset);
        }
      },
    );
  }

  Widget _buildManualVectorSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 9,
                color: Colors.grey[400],
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFFFD200).withValues(alpha: 0.7),
                inactiveTrackColor: Colors.white.withValues(alpha: 0.04),
                thumbColor: const Color(0xFFFFD200),
                trackHeight: 1.5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.5),
              ),
              child: Slider(
                value: value.clamp(-150.0, 150.0),
                min: -150.0,
                max: 150.0,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              value.toStringAsFixed(0),
              textAlign: TextAlign.end,
              style: GoogleFonts.orbitron(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
