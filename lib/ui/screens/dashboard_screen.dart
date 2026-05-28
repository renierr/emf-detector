import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../models/emf_reading.dart';
import '../../state/detector_state.dart';
import '../widgets/circular_gauge.dart';
import '../widgets/oscilloscope_chart.dart';
import '../widgets/scanner_header.dart';
import '../widgets/cable_detected_banner.dart';
import '../widgets/calibration_panel.dart';
import '../widgets/vector_readout_card.dart';
import '../widgets/oscilloscope_header.dart';
import '../widgets/scanner_controls_card.dart';
import '../widgets/simulator_lab_card.dart';

class DashboardScreen extends StatefulWidget {
  final DetectorState state;

  const DashboardScreen({super.key, required this.state});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _wakeLockActive = false;
  bool _automaticallyTurnedOnWakelock = false;

  @override
  void initState() {
    super.initState();
    _checkWakeLock();
    widget.state.addListener(_onStateChange);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (!mounted) return;
    if (widget.state.isScanning && !_wakeLockActive) {
      WakelockPlus.enable();
      setState(() {
        _wakeLockActive = true;
        _automaticallyTurnedOnWakelock = true;
      });
    } else if (!widget.state.isScanning && _wakeLockActive) {
      if (_automaticallyTurnedOnWakelock) {
        WakelockPlus.disable();
        setState(() {
          _wakeLockActive = false;
          _automaticallyTurnedOnWakelock = false;
        });
      }
    }
  }

  void _checkWakeLock() async {
    final active = await WakelockPlus.enabled;
    if (!mounted) return;
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
    if (!mounted) return;
    setState(() {
      _wakeLockActive = target;
      _automaticallyTurnedOnWakelock = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, child) {
        final state = widget.state;
        final current = state.currentReading ?? EmfReading.fromRaw(0, 0, 0);
        final isWarning =
            state.isScanning &&
            current.deltaMagnitude >= state.warningThreshold;

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Section
                      ScannerHeader(state: state),
                      const SizedBox(height: 24),

                      // Real-time status / alert banner (always displayed to prevent layout jumping)
                      CableDetectedBanner(
                        isScanning: state.isScanning,
                        isWarning: isWarning,
                      ),

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
                      CalibrationPanel(state: state),
                      const SizedBox(height: 24),

                      // 3-Axis Vector Breakdown
                      VectorReadoutCard(state: state, current: current),
                      const SizedBox(height: 20),

                      // Real-time scrolling chart
                      const OscilloscopeHeader(),
                      const SizedBox(height: 8),
                      OscilloscopeChart(
                        history: state.history,
                        threshold: state.warningThreshold,
                        isScanning: state.isScanning,
                        maxVal: 160.0,
                      ),
                      const SizedBox(height: 24),

                      // Controls & Feedback toggles
                      ScannerControlsCard(
                        state: state,
                        wakeLockActive: _wakeLockActive,
                        onToggleWakeLock: _toggleWakeLock,
                      ),
                      const SizedBox(height: 24),

                      // Developer Mode Dock (Mock Simulators)
                      SimulatorLabCard(state: state),
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
}
