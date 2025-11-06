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
// Conditionally imported web audio function
import '../utils/web_audio_player.dart'
    if (dart.library.js) '../utils/web_audio_player_web.dart';

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
  // Use AudioPool for polyphony (low-latency, non-clipping playback)
  AudioPool? _accentPool;
  AudioPool? _regularPool;

  // Track loaded source to avoid unnecessary loading
  String? _accentSource;
  String? _regularSource;

  // Single AudioPlayer instances are still declared but won't be used for playback, only for old logic removal.
  // We keep them as final but remove the final initialization to make room for pool initialization.
  // Keeping these lines commented out or removing them prevents confusion with the new pool approach.
  // final AudioPlayer player1 = AudioPlayer();
  // final AudioPlayer player2 = AudioPlayer();

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
    // Dispose old pools before creating new ones if sound selection changes
    await _accentPool?.dispose();
    await _regularPool?.dispose();

    // Determine the Source URL/Path
    Source? source1 = _getAudioSource(firstBeat);
    Source? source2 = _getAudioSource(secondBeat);

    if (source1 != null) {
        _accentPool = await AudioPool.create(
            source: source1,
            // Allow for a max of 4 simultaneous, overlapping instances
            maxPlayers: 4,
        );
        _accentSource = firstBeat;
    }

    if (source2 != null) {
        _regularPool = await AudioPool.create(
            source: source2,
            maxPlayers: 4,
        );
        _regularSource = secondBeat;
    }
  }

  // Helper to determine the correct Source type for audio assets
  Source? _getAudioSource(String beat) {
    if (kIsWeb) {
      // On Web, AudioPool does not support UrlSource directly, we rely on the implementation
      // of AssetSource pointing to the web asset structure (which is handled internally
      // by the package or Flutter's asset bundling).
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

    // BUG FIX: If metronome was playing, reset the timer with the new values
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

  // BUG FIX: New method to cleanly stop and reset the visual state
  void stopAndResetMetroState() {
    timer?.cancel();
    isPlaying = false;
    totalTick = 0;
    controller?.reset();
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
    await _accentPool?.dispose();
    await _regularPool?.dispose();
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
      // Call playSound directly
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
    // We add a short non-blocking delay here to allow the timer queue
    // to process the periodic tick event before triggering the audio playback.
    // This often improves perceived smoothness at high BPM.
    if (!kIsWeb) {
      // Small, non-blocking delay (e.g., 5-10ms)
      await Future.delayed(const Duration(milliseconds: 7));
    }

    AudioPool? poolToUse;

    if (beatIndicator.isEmpty) return;

    // Determine if it's the accented or regular beat
    if (totalTick < beatIndicator.length) {
      if (beatIndicator[totalTick].isAccentedBeat) {
        poolToUse = _accentPool;
      } else if (beatIndicator[totalTick].isPlanBeat) {
        poolToUse = _regularPool;
      }

      // Reset totalTick for the next cycle
      if (totalTick == beatIndicator.length - 1) {
        totalTick = 0;
      } else {
        totalTick += 1;
      }
    } else {
      // Catch case where totalTick might exceed index, reset to first beat for next cycle
      totalTick = 0;
      poolToUse = _accentPool; // Default to accent on measure restart
    }

    if (poolToUse != null) {
      // Trigger the low-latency play using the AudioPool.
      playBeat(poolToUse);
    }

    notifyListeners();
  }

  /// Plays a specific beat sound using the given pool
  void playBeat(AudioPool pool) {
    if (kIsWeb) {
      // Web implementation logic to determine the correct asset path,
      // but the actual playback needs to use the globally accessible function.
      String beat = (pool == _accentPool) ? firstBeat : secondBeat;
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

      // The globally imported function is now correctly called.
      playWebMetronomeSound(beat, 1.0);

    } else {
      // Trigger the low-latency play using AudioPool. The volume parameter is set at pool creation.
      pool.start();
    }
  }

  /// Plays a specific beat sound using the given player
  @Deprecated("Use playBeat(AudioPool pool) for polyphony instead.")
  Future<void> playBeat_Old(String beat, AudioPlayer player) async {
    // This is the old, clipping logic. We keep it to preserve the old web implementation.
    // The previous implementation used AudioPlayer for non-web, which is now replaced by AudioPool.
    // However, the original structure used to play sounds is preserved here for reference/fallback.
    final file = Utils.getAsset(beat);
    if (kIsWeb) {
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
              // 'https://musictools.io/mt-apps/mt-rhythm-toolkit',
              // localhost
              // 'http://localhost:8888/web',
            );
      // print('location ::: path: ${path}. file $logic1');
      await player.play(UrlSource(logic1));
      await player.setReleaseMode(ReleaseMode.stop);
      // playWebMetronomeSound(beat, jhgMetronomeVol);
    } else {
      //await player.stop();
      final file = Utils.getAsset(beat);
      if (file.existsSync()) {
        await player.play(DeviceFileSource(file.path));
      } else {
        await player.play(AssetSource(beat));
      }
      await player.setReleaseMode(ReleaseMode.stop);
    }
  }
}