import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:reg_page/reg_page.dart';
import 'package:rhythm_master/models/sound_model.dart';
import 'package:rhythm_master/services/local_db.dart';
import 'package:rhythm_master/utils/app_strings.dart';
import 'package:rhythm_master/utils/app_utils.dart';
import '../utils/app_assets.dart';

/// SpeedProvider manages the functionality of a speed trainer,
/// including BPM, intervals, and audio playback for tempo training.
class SpeedProvider extends ChangeNotifier {
  // Indicates if the speed trainer is currently playing
  bool isPlaying = false;

  // Current BPM (beats per minute)
  double bpm = 120;

  // Audio players for accented and regular beats
  final AudioPlayer player1 = AudioPlayer();
  final AudioPlayer player2 = AudioPlayer();

  // Timer for scheduling beat playback
  Timer? _timer;  

  // Start tempo and its range
  double startTempo = 120;
  final double startTempoMin = 1;
  final double startTempoMax = 300;

  // Target tempo and its range
  double targetTempo = 180;
  final double targetTempoMin = 1;
  final double targetTempoMax = 300;

  // Interval (how much BPM increases per cycle)
  int interval = 10;
  final int minInterval = 1;
  final int maxInterval = 120;

  // Bar (number of bars before increasing BPM)
  int bar = 2;
  int minBar = 1;
  int maxBar = 60;
  int defaultBar = 2;
  int defaultInterval = 1;
  int sliderInterval = 1;
  int totalBeats = 4;

  // Sound selection
  String soundName = AppStrings.logic;
  String firstBeat = AppAssets.logic1Sound;
  String secondBeat = AppAssets.logic2Sound;
  String? defaultBeatValue;
  double gafInterval = 1;

  // Bar and tick counters
  int totalTick = 0;
  int barCounter = 0;
  bool firstTime = true;

  // Time interval for a beat (ms)
  int timeStamp = 60000;

  /// Initializes the speed trainer and loads defaults
  Future<void> initializeAnimationController() async {
    Future.delayed(Duration.zero, () async {
      await setSpeedTrainerDefaultValue();
    });
  }

  /// Preloads metronome sounds for smooth playback
  Future<void> preloadSounds() async {
     Future.wait([
      player1.setVolume(0),
      player2.setVolume(0),
    ]);
    final directory1 = !kIsWeb ? Utils.getAsset(firstBeat) : AppUtils.setWebAsset(firstBeat);
    final directory2 = !kIsWeb ? Utils.getAsset(secondBeat) : AppUtils.setWebAsset(secondBeat);
     Future.wait([
      player1.setFilePath(directory1.path, preload: true),
      player2.setFilePath(directory2.path, preload: true),
    ]);
  }

  /// Loads default values for the speed trainer from storage
  Future<void> setSpeedTrainerDefaultValue() async {
    final results = await Future.wait([
      SharedPref.getStoreSpeedTrainerDefaultSound,
      SharedPref.getSpeedTrainerDefaultValue,
      SharedPref.getSpeedTrainerDefaultInterval,
    ]);
    final defSound = results[0] as int?;
    final defValue = results[1] as String?;
    final defSpeedInterval = results[2] as double?;
    gafInterval = defSpeedInterval ?? 1;
    defaultBeatValue = defValue ?? "4/4";
    if (defSound == null) {
      soundName = AppStrings.logic;
      firstBeat = AppAssets.logic1Sound;
      secondBeat = AppAssets.logic2Sound;
    } else {
      final sound = soundList[defSound];
      soundName = sound.name!;
      firstBeat = sound.beat1!;
      secondBeat = sound.beat2!;
    }
    getBeatsDuration(defaultBeatValue!);
    await preloadSounds();
    notifyListeners();
  }

  /// Sets the number of beats and the time interval for a beat
  void getBeatsDuration(String value) {
    final beatValue = value.split("/");
    final beatN = int.parse(beatValue[0]);
    final beatD = int.parse(beatValue[1]);
    totalBeats = beatN;
    final Map<int, int> beatDurationMap = {
      2: 120000,
      4: 60000,
      8: 30000,
      16: 15000,
      32: 7500,
      64: 3750,
    };
    timeStamp = beatDurationMap[beatD] ?? 60000;
    notifyListeners();
  }

  /// Clears all speed trainer settings and stops playback
  void clearSpeedTrainer(bool isNotify) {
    _timer?.cancel();
    isPlaying = false;
    bpm = 120;
    startTempo = 120;
    targetTempo = 180;
    interval = defaultInterval;
    bar = defaultBar;
    totalTick = 0;
    barCounter = 0;
    if (isNotify) {
      notifyListeners();
    }
  }

  /// Sets the start tempo and updates state
  void setStartTempo(double value) {
    startTempo = value;
    bpm = startTempo;
    barCounter = 0;
    totalTick = 0;
    firstTime = true;
    notifyListeners();
    if (isPlaying) {
      setTimer();
    }
  }

  /// Sets the target tempo and updates state
  void setTargetTempo(double value) {
    targetTempo = value;
    barCounter = 0;
    totalTick = 0;
    firstTime = true;
    notifyListeners();
    if (isPlaying) {
      setTimer();
    }
  }

  /// Sets the interval for BPM increase
  void onChangedInterval(int newValue) {
    interval = newValue;
    notifyListeners();
    if (isPlaying) {
      setTimer();
    }
  }

  /// Sets the number of bars before BPM increases
  void onChangedBar(int newValue) {
    bar = newValue;
    totalTick = 0;
    barCounter = 0;
    firstTime = true;
    notifyListeners();
    if (isPlaying) {
      setTimer();
    }
  }

  /// Sets the default bar value
  void onChangedDefaultBar(int newValue) {
    defaultBar = newValue;
    notifyListeners();
  }

  /// Sets the default interval value
  void onChangedDefaultInterval(int newValue) {
    defaultInterval = newValue;
    notifyListeners();
  }

  /// Sets the slider interval value
  void onChangedSliderInterval(int newValue) {
    sliderInterval = newValue;
    notifyListeners();
  }

  /// Starts or stops the speed trainer
  void startStop() {
    totalTick = 0;
    barCounter = 0;
    firstTime = true;
    if (isPlaying) {
      _timer?.cancel();
    } else {
      setTimer();
    }
    isPlaying = !isPlaying;
    notifyListeners();
  }

  /// Sets the timer for beat playback and BPM increase
  void setTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(milliseconds: (timeStamp / bpm).round()),
      (Timer timer) async {
        if (targetTempo + interval > bpm) {
           playSound();
        } else {
          _timer?.cancel();
          totalTick = 0;
          barCounter = 0;
          isPlaying = false;
          firstTime = true;
          bpm = targetTempo;
          notifyListeners();
        }
      },
    );
  }

  /// Plays the appropriate sound for the current tick and manages BPM increase
  Future<void> playSound() async {
    if (player1.volume == 0 || player2.volume == 0) {
      Future.wait([
       player1.setVolume(1.0),
       player2.setVolume(1.0),
      ]);

    }
    barCounter++;
    totalTick++;
    if (totalTick == 1) {
      // Check if it's time to increase BPM
      final bool shouldIncrease = firstTime
          ? barCounter - 1 == bar * totalBeats
          : barCounter == bar * totalBeats;
      if (shouldIncrease) {
        bpm += interval;
        barCounter = 0;
        firstTime = false;
        notifyListeners();
        setTimer();
      }
      // If we've reached the target tempo, stop increasing
      if (bpm >= targetTempo + bar * interval) return;
      playBeat(player1);
    } else {
      if (totalTick < totalBeats) {
        playBeat(player2);
      } else {
        totalTick = 0;
        playBeat(player2);
      }
    }
  }

  /// Plays the accented beat sound
  // Future<void> playBeat1() async {
  //   await player1.seek(Duration.zero);
  //   await player1.load();
  //   await player1.play();
  // }

  /// Plays the regular beat sound
  // Future<void> playBeat2() async {
  //   Future.wait([
  //    player2.seek(Duration.zero),
  //    player2.load(),
  //    player2.play(),
  //   ]);
  // }
  //
  playBeat(AudioPlayer player){
    Future.wait([
      player.seek(Duration.zero),
      player.load(),
      player.play(),
    ]);
  }

  /// Increments the start tempo by [interval], clamped to targetTempo
  void incrementTempo(int interval) {
    startTempo = adjustTempo(startTempo + interval, targetTempo);
    bpm = startTempo;
    notifyListeners();
  }

  /// Decrements the start tempo by [interval], clamped to 1
  void decrementTempo(int interval) {
    startTempo = adjustTempo(startTempo - interval, targetTempo);
    bpm = startTempo;
    notifyListeners();
  }

  /// Increments the target tempo by [interval], clamped to 300
  void incrementTargetTempo(int interval) {
    targetTempo = adjustTempo(targetTempo + interval, 300);
    notifyListeners();
  }

  /// Decrements the target tempo by [interval], clamped to 1
  void decrementTargetTempo(int interval) {
    targetTempo = adjustTempo(targetTempo - interval, 300);
    notifyListeners();
  }

  /// Ensures tempo stays within a valid range
  double adjustTempo(double newTempo, double limit) {
    if (newTempo > limit) {
      return limit;
    } else if (newTempo < 1) {
      return 1;
    }
    return newTempo;
  }
}
