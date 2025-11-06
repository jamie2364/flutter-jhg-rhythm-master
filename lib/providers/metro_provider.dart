import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:reg_page/reg_page.dart';
import 'package:rhythm_master/models/sound_model.dart';
import 'package:rhythm_master/services/local_db.dart';
import 'package:rhythm_master/utils/app_strings.dart';
import 'package:universal_html/html.dart' hide Animation;

import '../models/beat_indicator_model.dart';
import '../utils/app_assets.dart';

/// MetroProvider manages metronome state, BPM, beats, and sound playback.
class MetroProvider extends ChangeNotifier {
  // List of beat indicators for UI
  List<BeatIndicator> beatIndicator = [];

  /// Creates the beat indicator list based on totalBeat
  void createBeatIndicatorList() {
    if (totalBeat > 12) {
      setBeatIndicatorState(true);
      return;
    }
    setBeatIndicatorState(false);
    beatIndicator = List.generate(
      totalBeat,
      (index) => BeatIndicator(
        isAccentedBeat: index == 0,
        isMutedBeat: false,
        isPlanBeat: index != 0,
      ),
    );
    notifyListeners();
  }

  /// Cycles the state of a beat indicator at [selectedIndex]
  void updateBeatIndicatorList(int selectedIndex) {
    if (selectedIndex < 0 || selectedIndex >= beatIndicator.length) return;
    final beat = beatIndicator[selectedIndex];
    if (beat.isAccentedBeat) {
      beat.isAccentedBeat = false;
      beat.isPlanBeat = true;
      beat.isMutedBeat = false;
    } else if (beat.isPlanBeat) {
      beat.isAccentedBeat = false;
      beat.isPlanBeat = false;
      beat.isMutedBeat = true;
    } else if (beat.isMutedBeat) {
      beat.isAccentedBeat = true;
      beat.isPlanBeat = false;
      beat.isMutedBeat = false;
    }
    notifyListeners();
  }

  // Controls visibility of beat indicator
  bool hideBeatIndicator = false;
  void setBeatIndicatorState(bool state) {
    if (hideBeatIndicator != state) {
      hideBeatIndicator = state;
      notifyListeners();
    }
  }

  // Beat and time signature values
  int beatNumerator = 2;
  int beatDenominator = 2;

  // BPM and slider values
  Timer? bpmContinuousTimer;
  double bpm = 120;
  final double bpmMin = 1.0;
  final double bpmMax = 300.0;
  double position = 0;
  int totalBeat = 4;
  int totalTick = 0;
  bool isPlaying = false;

  // Animation controller for metronome UI
  AnimationController? controller;
  AnimationController? pulseController;
  Animation<double>? animation;

  // Audio players for metronome sounds
  // Use a pool of players for low-latency, rapid playback
  final AudioPlayer _accentPlayer = AudioPlayer();
  final AudioPlayer _regularPlayer = AudioPlayer();

  // Track loaded source to avoid unnecessary loading
  String? _accentSource;
  String? _regularSource;

  int? selectedIndex;
  double timeStamp = 0;
  double? defaultBPM;
  int? defaultSound;
  int? defaultTiming;
  String? defaultBeatValue;
  bool firstTime = true;
  bool isRepeat = true;
  Timer? timer;

  // Sound selection
  String soundName = AppStrings.logic;
  String firstBeat = AppAssets.logic1Sound;
  String secondBeat = AppAssets.logic2Sound;
  int selectedButton = 0;

  // List of available time signatures for tap buttons in the UI
  List<String> tapButtonList = ['4/4', '3/4', '6/8', '12/8'];

  /// Resets bottom sheet beat values
  void clearBottomSheetBeats() {
    beatNumerator = 2;
    beatDenominator = 2;
    notifyListeners();
  }

  /// Preloads metronome sounds for smooth playback
  Future<void> preloadSounds() async {
    // 1. Set the two necessary audio sources.
    Source? source1 = _getAudioSource(firstBeat);
    Source? source2 = _getAudioSource(secondBeat);

    // 2. Preload the audio files for faster, non-blocking playback.
    if (source1 != null) {
      await _accentPlayer.setSource(source1);
      _accentSource = firstBeat;
    }
    if (source2 != null) {
      await _regularPlayer.setSource(source2);
      _regularSource = secondBeat;
    }

    // Set low-latency mode if possible and required (though setSource is often sufficient for preloading)
    await Future.wait([
      _accentPlayer.setVolume(1.0),
      _regularPlayer.setVolume(1.0),
      _accentPlayer.setReleaseMode(ReleaseMode.stop),
      _regularPlayer.setReleaseMode(ReleaseMode.stop),
    ]);
  }

  // Helper to determine the correct Source type for audio assets
  Source? _getAudioSource(String beat) {
    if (kIsWeb) {
      // Web assets are handled uniquely in the playBeat function, this just provides the AssetSource for non-web logic flow
      return AssetSource(beat);
    } else {
      final file = Utils.getAsset(beat);
      if (file.existsSync()) {
        return DeviceFileSource(file.path);
      } else {
        return AssetSource(beat);
      }
    }
  }

  /// Increments numerator (max 96)
  void incrementBeatNumerator() {
    if (beatNumerator < 96) {
      beatNumerator++;
      notifyListeners();
    }
  }

  /// Decrements numerator (min 2)
  void decrementBeatNumerator() {
    if (beatNumerator > 2) {
      beatNumerator--;
      notifyListeners();
    }
  }

  /// Doubles denominator (max 64)
  void incrementBeatDenominator() {
    if (beatDenominator < 64) {
      beatDenominator *= 2;
      notifyListeners();
    }
  }

  /// Halves denominator (min 2)
  void decrementBeatDenominator() {
    if (beatDenominator > 2) {
      beatDenominator ~/= 2;
      notifyListeners();
    }
  }

  String? customBeatValue;

  /// Sets custom beat value from bottom sheet
  void setValueOfBottomSheet(TickerProviderStateMixin ticker) {
    selectedButton = 4;
    final value = "$beatNumerator/$beatDenominator";
    customBeatValue = value;
    notifyListeners();
    getBeatsDuration(value, selectedButton);
    createBeatIndicatorList();
    if (isPlaying) {
      setTimer(ticker);
    }
  }

  /// Sets the time interval for a beat
  void setTimeStamp(int value) {
    timeStamp = 240000 / value;
    notifyListeners();
  }

  double gafInterval = 1;

  /// Initializes the animation controller for the metronome
  Future<void> initializeAnimationController(
      TickerProviderStateMixin ticker) async {
    timer?.cancel();
    controller = AnimationController(
      duration: Duration(milliseconds: (30000 / bpm).round()),
      vsync: ticker,
    );
    animation = Tween<double>(begin: 0, end: 1).animate(controller!);
    controller!.repeat(reverse: true);
    controller!.stop();
    Future.delayed(Duration.zero, () async {
      await setMetronomeDefaultValue();
    });
  }

  /// Loads default metronome values from storage
  Future<void> setMetronomeDefaultValue() async {
    final results = await Future.wait([
      SharedPref.getDefaultBPM,
      SharedPref.getDefaultSound,
      SharedPref.getDefaultTiming,
      SharedPref.getMetronomeDefaultValue,
      SharedPref.getMetronomeDefaultInterval,
    ]);
    defaultBPM = results[0] as double? ?? 120;
    defaultSound = results[1] as int? ?? 0;
    defaultTiming = results[2] as int? ?? 0;
    defaultBeatValue = results[3] as String? ?? "4/4";
    gafInterval = results[4] as double? ?? 1;
    selectedButton = defaultTiming!;
    bpm = defaultBPM!;
    position = 0;
    totalTick = 0;
    isPlaying = false;
    getBeatsDuration(defaultBeatValue!, selectedButton);

    // Update current sound based on defaults
    soundName = soundList[selectedIndex ?? defaultSound!].name!;
    firstBeat = soundList[selectedIndex ?? defaultSound!].beat1!;
    secondBeat = soundList[selectedIndex ?? defaultSound!].beat2!;

    await preloadSounds();
    createBeatIndicatorList();
    notifyListeners();
  }

  /// Disposes the animation controller and timers
  Future<void> disposeController() async {
    timer?.cancel();
    bpmContinuousTimer?.cancel();
    isPlaying = false;
    controller?.dispose();
    controller = null;
    pulseController?.dispose();
    pulseController = null;
    await _accentPlayer.dispose(); // Dispose the individual players
    await _regularPlayer.dispose();
  }

  /// Resets the metronome to default values
  void clearMetronome() {
    timer?.cancel();
    if (controller != null) {
      animation = Tween<double>(begin: 0, end: 1).animate(controller!);
      controller!.reset();
    }
    setMetronomeDefaultValue();
    notifyListeners();
  }

  /// Resets custom bottom sheet values
  void resetMetronomeCustomBottomSheet() {
    beatNumerator = 2;
    beatDenominator = 2;
    notifyListeners();
  }

  /// Sets the slider position and BPM
  void setPosition(double value, TickerProviderStateMixin ticker) {
    position = value;
    bpm = value;
    totalTick = 0;
    notifyListeners();
    if (isPlaying) {
      setTimer(ticker);
    }
  }

  /// Adjusts BPM by [increment] and updates timer if playing
  void adjustBpm(TickerProviderStateMixin ticker, int increment) {
    final newBpm = bpm + increment;
    if (newBpm >= bpmMin && newBpm <= bpmMax) {
      totalTick = 0;
      bpm = newBpm;
      notifyListeners();
      if (isPlaying) {
        setTimer(ticker);
      }
    }
  }

  /// Starts continuous BPM adjustment
  void startContinuousBpmAdjustment(
      TickerProviderStateMixin ticker, int increment) {
    bpmContinuousTimer?.cancel();
    bpmContinuousTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      adjustBpm(ticker, increment);
    });
  }

  // Public methods for BPM adjustment
  void increaseBpm(TickerProviderStateMixin ticker) => adjustBpm(ticker, 1);
  void decreaseBpm(TickerProviderStateMixin ticker) => adjustBpm(ticker, -1);
  void continuousIncreaseBpm(TickerProviderStateMixin ticker) =>
      startContinuousBpmAdjustment(ticker, 1);
  void continuousDecreaseBpm(TickerProviderStateMixin ticker) =>
      startContinuousBpmAdjustment(ticker, -1);

  /// Starts or stops the metronome
  Future<void> startStop(TickerProviderStateMixin ticker) async {
    firstTime = true;
    totalTick = 0;
    if (isPlaying) {
      controller?.reset();
      animation = controller != null
          ? Tween<double>(begin: 0, end: 1).animate(controller!)
          : null;
      timer?.cancel();
    } else {
      setTimer(ticker);
    }
    isPlaying = !isPlaying;
    notifyListeners();
  }

  /// Sets the timer and animation for the metronome
  void setTimer(TickerProviderStateMixin ticker) {
    totalTick = 0;
    firstTime = true;

    // The core calculation remains correct
    final timerInterval = (timeStamp / bpm).round();

    controller?.stop();
    controller?.dispose();
    timer?.cancel();

    controller = AnimationController(
      duration: Duration(milliseconds: timerInterval),
      vsync: ticker,
    );
    animation = Tween<double>(begin: 0, end: 1).animate(controller!);

    bool reverseHandled = false;

    // Timer is set to the calculated interval (e.g., 270ms)
    timer = Timer.periodic(Duration(milliseconds: timerInterval), (_) {
      // Call playSound directly, it now uses a non-awaiting play mechanism
      playSound();
    });

    controller!.addStatusListener((status) {
      if (status == AnimationStatus.forward && firstTime) {
        firstTime = false;
      }
      if (status == AnimationStatus.reverse && !reverseHandled) {
        reverseHandled = true;
        animation = Tween<double>(begin: -1, end: 1).animate(controller!);
        controller!.repeat(reverse: true);
      }
    });
    controller!.repeat(reverse: true);
  }

  /// Sets beats and updates state based on selected button
  void getBeatsDuration(String value, int buttonIndex) {
    final beatValue = value.split("/");
    final beatN = int.parse(beatValue[0]);
    final beatD = int.parse(beatValue[1]);
    totalBeat = beatN;
    final Map<int, double> beatDurations = {
      2: 120000,
      4: 60000,
      8: 30000,
      16: 15000,
      32: 7500,
      64: 3750,
    };
    timeStamp = beatDurations[beatD] ?? 60000;
    if (selectedButton == 4) {
      customBeatValue = value;
      beatNumerator = beatN;
      beatDenominator = beatD;
    }
    notifyListeners();
  }

  /// Sets beats for a given index and value
  void setBeats(
      {required TickerProviderStateMixin ticker,
      required int index,
      required String indexValue}) {
    customBeatValue = null;
    selectedButton = index;
    beatNumerator = 2;
    beatDenominator = 2;
    notifyListeners();
    getBeatsDuration(indexValue, index);
    createBeatIndicatorList();
    if (isPlaying) {
      setTimer(ticker);
    }
  }

  /// Sets the selected sound and updates state
  void setSound(
      {required TickerProviderStateMixin? ticker,
      required String name,
      required String beat1,
      required String beat2,
      required int index}) {
    selectedIndex = index;
    soundName = name;
    firstBeat = beat1;
    secondBeat = beat2;
    totalTick = 0;

    // Check if new sounds are different and reload if necessary
    if (firstBeat != _accentSource || secondBeat != _regularSource) {
      preloadSounds();
    }

    notifyListeners();
    if (ticker == null) return;
    if (isPlaying) {
      setTimer(ticker);
    }
  }

  /// Plays the appropriate sound for the current tick
  Future<void> playSound() async {
    // Determine which player to use for the current tick
    AudioPlayer? playerToUse;

    if (beatIndicator.isEmpty) return;

    // Determine if it's the accented or regular beat
    if (totalTick < beatIndicator.length) {
      if (beatIndicator[totalTick].isAccentedBeat) {
        playerToUse = _accentPlayer;
      } else if (beatIndicator[totalTick].isPlanBeat) {
        playerToUse = _regularPlayer;
      }
      // If isMutedBeat, playerToUse remains null, so no sound is played.

      // Reset totalTick for the next cycle
      if (totalTick == beatIndicator.length - 1) {
        totalTick = 0;
      } else {
        totalTick += 1;
      }
    } else {
      // Catch case where totalTick might exceed index, reset to first beat for next cycle
      totalTick = 0;
      playerToUse = _accentPlayer; // Default to accent on measure restart
    }

    if (playerToUse != null) {
      // Trigger the low-latency play without awaiting, minimizing timer blocking
      // We rely on the player already being loaded from preloadSounds.
      playBeat(playerToUse);
    }

    notifyListeners();
  }

  /// Plays a specific beat sound using the given player (now non-async and non-blocking)
  // This method is now non-async as it relies on pre-loaded sources for fast playback.
  void playBeat(AudioPlayer player) {
    if (kIsWeb) {
      // Web implementation is handled differently and likely still needs the file path logic
      String beat = (player == _accentPlayer) ? firstBeat : secondBeat;
      var file = Utils.getAsset(beat);
      var logic1 = kDebugMode ? file.path : file.path.replaceAll('web/', '');
      String path =
          window.location.href.substring(0, window.location.href.length - 1);
      Uri uri = Uri.parse(path);
      path = uri.replace(query: "").toString();
      path = path.replaceAll('/?', '');
      logic1 = kDebugMode
          ? file.path.replaceAll('null', 'web')
          : file.path.replaceAll(
              'null',
              // live
              path,
            );
      player.play(UrlSource(logic1)); // Use .play() without await
    } else {
      // For mobile/desktop, simply call resume/seek to 0 on the pre-loaded player
      player.seek(Duration.zero);
      player.resume();
    }
  }
}