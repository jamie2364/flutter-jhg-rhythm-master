import 'package:flutter/foundation.dart';

/// TapTempoProvider handles tap tempo functionality, calculates BPM,
/// and determines music tempo names based on the calculated BPM.
class TapTempoProvider extends ChangeNotifier {
  /// Stores the intervals (in ms) between taps
  final List<double> tapIntervals = [];

  /// Timestamp of the last tap (ms since epoch)
  double? tapTimestamp;

  /// Calculated BPM value
  double? bpm;

  /// Music tempo name based on BPM
  String musicName = '';

  /// Button scale for tap animation
  double buttonScale = 1;

  /// Handles a tap event, updates BPM and tempo name
  void handleTap() async {
    // Animate tap button
    buttonScale = 1.1;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 100), () {
      buttonScale = 1;
      notifyListeners();
    });

    final currentTime = DateTime.now().millisecondsSinceEpoch.toDouble();

    if (tapTimestamp != null) {
      final interval = currentTime - tapTimestamp!;
      // Ignore intervals that are too short or too long
      if (interval > 100 && interval < 3000) {
        tapIntervals.add(interval);
        // Keep only the last 5 intervals
        if (tapIntervals.length > 5) {
          tapIntervals.removeAt(0);
        }
        // Calculate average BPM
        final averageInterval = tapIntervals.reduce((a, b) => a + b) / tapIntervals.length;
        bpm = 60000 / averageInterval;
        notifyListeners();
      }
    }
    tapTimestamp = currentTime;
    if (bpm != null) {
      setAudioName();
    }
  }

  /// Sets the musicName based on the current BPM value
  void setAudioName() {
    final value = bpm ?? 0;
    if (value <= 20) {
      musicName = "Larghissimo";
    } else if (value <= 40) {
      musicName = "Grave";
    } else if (value <= 45) {
      musicName = "Lento";
    } else if (value <= 50) {
      musicName = "Largo";
    } else if (value <= 65) {
      musicName = "Adagio";
    } else if (value <= 69) {
      musicName = "Adagietto";
    } else if (value <= 77) {
      musicName = "Andante";
    } else if (value <= 97) {
      musicName = "Moderato";
    } else if (value <= 109) {
      musicName = "Allegretto";
    } else if (value <= 132) {
      musicName = "Allegro";
    } else if (value < 140) {
      musicName = "Vivace";
    } else if (value < 177) {
      musicName = "Presto";
    } else if (value >= 178) {
      musicName = "Prestissimo";
    } else {
      musicName = " ";
    }
    notifyListeners();
  }

  /// Clears all BPM data and resets values
  void clearBPM() {
    tapTimestamp = null;
    musicName = '';
    tapIntervals.clear();
    bpm = null;
    notifyListeners();
  }
}