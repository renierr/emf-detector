import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  AudioPlayer? _audioPlayer;
  String? _soundFilePath;
  bool _initialized = false;
  bool _isEnabled = false;

  Timer? _tickerTimer;
  double _currentIntervalMs = 0.0;

  AudioService() {
    _initSoundFile();
  }

  bool get isEnabled => _isEnabled;

  /// Enable or disable beep sounds.
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!_isEnabled) {
      _tickerTimer?.cancel();
      _tickerTimer = null;
    }
  }

  /// Synthesizes a tiny 20ms Geiger-counter click WAV file and writes it to disk.
  /// This bypasses standard asset bundling, making it completely self-contained.
  Future<void> _initSoundFile() async {
    try {
      _audioPlayer = AudioPlayer();
      // Configure audio player for low latency
      await _audioPlayer?.setReleaseMode(ReleaseMode.stop);

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}${Platform.pathSeparator}emf_geiger_tick.wav',
      );

      // Wave file properties: Upgrade to 16-bit PCM at 44.1kHz to guarantee compatibility
      // on both Windows (WASAPI) and all physical Android devices.
      const int sampleRate = 44100;
      const int numSamples = 882; // 44100 * 0.02 = 882 samples (20ms click)
      const int bitsPerSample = 16;
      const int blockAlign = 2; // 1 channel * 16 bits / 8 = 2 bytes
      const int byteRate = sampleRate * blockAlign; // 88200 bytes/sec
      const int subchunk2size =
          numSamples * blockAlign; // 1764 bytes of PCM data
      final int fileSize = 36 + subchunk2size; // 1800 bytes total file size

      final List<int> wavBytes = [];

      // WAV Header
      // 1. RIFF Identifier
      wavBytes.addAll([0x52, 0x49, 0x46, 0x46]); // "RIFF"
      // 2. Size (36 + subchunk2size)
      wavBytes.addAll([
        fileSize & 0xFF,
        (fileSize >> 8) & 0xFF,
        (fileSize >> 16) & 0xFF,
        (fileSize >> 24) & 0xFF,
      ]);
      // 3. Format
      wavBytes.addAll([0x57, 0x41, 0x56, 0x45]); // "WAVE"

      // Subchunk 1 (fmt)
      wavBytes.addAll([0x66, 0x6D, 0x74, 0x20]); // "fmt "
      wavBytes.addAll([16, 0, 0, 0]); // Subchunk1Size = 16
      wavBytes.addAll([1, 0]); // AudioFormat = 1 (PCM)
      wavBytes.addAll([1, 0]); // NumChannels = 1 (Mono)
      // SampleRate (44100)
      wavBytes.addAll([
        sampleRate & 0xFF,
        (sampleRate >> 8) & 0xFF,
        (sampleRate >> 16) & 0xFF,
        (sampleRate >> 24) & 0xFF,
      ]);
      // ByteRate (88200)
      wavBytes.addAll([
        byteRate & 0xFF,
        (byteRate >> 8) & 0xFF,
        (byteRate >> 16) & 0xFF,
        (byteRate >> 24) & 0xFF,
      ]);
      wavBytes.addAll([blockAlign, 0]); // BlockAlign = 2
      wavBytes.addAll([bitsPerSample, 0]); // BitsPerSample = 16

      // Subchunk 2 (data)
      wavBytes.addAll([0x64, 0x61, 0x74, 0x61]); // "data"
      wavBytes.addAll([
        subchunk2size & 0xFF,
        (subchunk2size >> 8) & 0xFF,
        (subchunk2size >> 16) & 0xFF,
        (subchunk2size >> 24) & 0xFF,
      ]);

      // Sound generation: High pitch Geiger tick (sine wave with steep exponential decay envelope)
      const double frequency = 1800.0; // 1.8 kHz sharp beep
      for (int i = 0; i < numSamples; i++) {
        final double t = i / sampleRate;
        // Exponential decay envelope makes it sound like a tight "tick"
        final double envelope = exp(-t * 220.0);
        final double sine = sin(2 * pi * frequency * t);

        // Convert to 16-bit signed integer [-32768, 32767]
        final int sampleVal = (32767 * envelope * sine).round().clamp(
          -32768,
          32767,
        );

        // Write little-endian bytes
        wavBytes.add(sampleVal & 0xFF);
        wavBytes.add((sampleVal >> 8) & 0xFF);
      }

      await file.writeAsBytes(wavBytes, flush: true);
      _soundFilePath = file.absolute.path;
      debugPrint(
        '[AudioService] Geiger-click WAV successfully synthesized and saved at: $_soundFilePath',
      );

      // Warm up source loading
      await _audioPlayer?.setSource(DeviceFileSource(_soundFilePath!));
      _initialized = true;
    } catch (e) {
      debugPrint('[AudioService] Failed to synthesize sound file: $e');
    }
  }

  /// Triggers a single instant tick sound.
  Future<void> playTick() async {
    if (!_initialized || _soundFilePath == null || _audioPlayer == null) return;
    try {
      // Direct play is much more reliable and faster than seek-resume on desktop/mobile backends.
      // Calling stop() first immediately resets the player status, eliminating async seek delays.
      await _audioPlayer!.stop();
      await _audioPlayer!.play(DeviceFileSource(_soundFilePath!));
    } catch (e) {
      debugPrint('[AudioService] Error playing click sound: $e');
    }
  }

  /// Dynamically updates the beeper interval based on the current EMF delta reading
  /// relative to the warning threshold.
  ///
  /// - Below 5 uT: No beep (silent background)
  /// - 5 uT to Threshold: Slow pacing ticks (from 1.5 seconds down to 300ms)
  /// - Above Threshold: Rapid alarm-like ticking (from 300ms down to 45ms)
  void updateSignalStrength(double deltaMag, double threshold) {
    if (!_isEnabled || !_initialized) return;

    if (deltaMag < 4.0) {
      // Too weak to beep, stop the timer
      _tickerTimer?.cancel();
      _tickerTimer = null;
      return;
    }

    double intervalMs;

    if (deltaMag >= threshold) {
      // High alarm range
      // Map magnitude from [threshold, threshold + 100] to [300ms, 45ms]
      final overRatio = ((deltaMag - threshold) / 100.0).clamp(0.0, 1.0);
      intervalMs = 300.0 - (overRatio * 255.0); // Minimum 45ms interval
    } else {
      // Warning/approaching range [4.0, threshold]
      final rangeRatio = ((deltaMag - 4.0) / (threshold - 4.0)).clamp(0.0, 1.0);
      intervalMs = 1500.0 - (rangeRatio * 1200.0); // Down to 300ms
    }

    _currentIntervalMs = intervalMs;

    // Restart timer with the updated interval if it significantly changes
    _startTickerLoop();
  }

  void _startTickerLoop() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(
      Duration(milliseconds: _currentIntervalMs.round()),
      (timer) {
        if (!_isEnabled) {
          timer.cancel();
          return;
        }
        playTick();
      },
    );
  }

  void dispose() {
    _tickerTimer?.cancel();
    _audioPlayer?.dispose();
  }
}
