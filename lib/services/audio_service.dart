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
      final file = File('${tempDir.path}/emf_geiger_tick.wav');

      // Wave file properties
      const int sampleRate = 11025;
      const int numSamples = 220; // 11025 * 0.02 = 220 samples

      final List<int> wavBytes = [];

      // WAV Header
      // 1. RIFF Identifier
      wavBytes.addAll([0x52, 0x49, 0x46, 0x46]); // "RIFF"
      // 2. Size (36 + subchunk2size)
      final int subchunk2size = numSamples; // 8-bit mono has 1 byte per sample
      final int fileSize = 36 + subchunk2size;
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
      // SampleRate = 11025
      wavBytes.addAll([
        sampleRate & 0xFF,
        (sampleRate >> 8) & 0xFF,
        (sampleRate >> 16) & 0xFF,
        (sampleRate >> 24) & 0xFF,
      ]);
      // ByteRate = SampleRate * NumChannels * BitsPerSample / 8 = 11025 * 1 * 8 / 8 = 11025
      wavBytes.addAll([
        sampleRate & 0xFF,
        (sampleRate >> 8) & 0xFF,
        (sampleRate >> 16) & 0xFF,
        (sampleRate >> 24) & 0xFF,
      ]);
      wavBytes.addAll([1, 0]); // BlockAlign = 1
      wavBytes.addAll([8, 0]); // BitsPerSample = 8

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
        // Exponential decay envelope makes it sound like a "tick" instead of a flat beep
        final double envelope = exp(-t * 220.0); 
        final double sine = sin(2 * pi * frequency * t);
        
        // Convert range [-1.0, 1.0] to unsigned 8-bit [0, 255]
        final int sampleVal = (128 + 110 * envelope * sine).round().clamp(0, 255);
        wavBytes.add(sampleVal);
      }

      await file.writeAsBytes(wavBytes, flush: true);
      _soundFilePath = file.path;
      
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
      // Re-trigger playback by seeking to beginning and resuming
      await _audioPlayer!.seek(Duration.zero);
      await _audioPlayer!.resume();
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
    _tickerTimer = Timer.periodic(Duration(milliseconds: _currentIntervalMs.round()), (timer) {
      if (!_isEnabled) {
        timer.cancel();
        return;
      }
      playTick();
    });
  }

  void dispose() {
    _tickerTimer?.cancel();
    _audioPlayer?.dispose();
  }
}
