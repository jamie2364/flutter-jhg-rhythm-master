import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:just_audio/just_audio.dart';
import 'package:reg_page/reg_page.dart';
import 'package:rhythm_master/models/sound_model.dart';
import 'package:rhythm_master/services/local_db.dart';
import 'package:rhythm_master/utils/app_strings.dart';
import 'package:rhythm_master/utils/app_utils.dart';

import '../models/beat_indicator_model.dart';
import '../utils/app_assets.dart';
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
    beatIndicator = List.generate(totalBeat, (index) =>
      BeatIndicator(
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
  Animation<double>? animation;

  // Audio players for metronome sounds
  final AudioPlayer player1 = AudioPlayer();
  final AudioPlayer player2 = AudioPlayer();

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
  Future<void> initializeAnimationController(TickerProviderStateMixin ticker) async {
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
  void startContinuousBpmAdjustment(TickerProviderStateMixin ticker, int increment) {
    bpmContinuousTimer?.cancel();
    bpmContinuousTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      adjustBpm(ticker, increment);
    });
  }

  // Public methods for BPM adjustment
  void increaseBpm(TickerProviderStateMixin ticker) => adjustBpm(ticker, 1);
  void decreaseBpm(TickerProviderStateMixin ticker) => adjustBpm(ticker, -1);
  void continuousIncreaseBpm(TickerProviderStateMixin ticker) => startContinuousBpmAdjustment(ticker, 1);
  void continuousDecreaseBpm(TickerProviderStateMixin ticker) => startContinuousBpmAdjustment(ticker, -1);

  /// Starts or stops the metronome
  Future<void> startStop(TickerProviderStateMixin ticker) async {
    firstTime = true;
    totalTick = 0;
    if (isPlaying) {
      controller?.reset();
      animation = controller != null ? Tween<double>(begin: 0, end: 1).animate(controller!) : null;
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
    controller?.reset();
    controller?.dispose();
    final timerInterval = (timeStamp / bpm).round();
    controller = AnimationController(
      duration: Duration(milliseconds: timerInterval),
      vsync: ticker,
    );
    animation = Tween<double>(begin: 0, end: 1).animate(controller!);
    timer?.cancel();
    timer = Timer.periodic(Duration(milliseconds: timerInterval), (_) {
      playSound();
    });
    controller!.repeat(reverse: true);
    controller!.addStatusListener((status) {
      if (status == AnimationStatus.forward && firstTime) {
        firstTime = false;
      }
      if (status == AnimationStatus.reverse && firstTime) {
        animation = Tween<double>(begin: -1, end: 1).animate(controller!);
        controller!.repeat(reverse: true);
      }
    });
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
  void setBeats({required TickerProviderStateMixin ticker, required int index, required String indexValue}) {
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
  void setSound({required TickerProviderStateMixin? ticker, required String name, required String beat1, required String beat2, required int index}) {
    selectedIndex = index;
    soundName = name;
    firstBeat = beat1;
    secondBeat = beat2;
    totalTick = 0;
    notifyListeners();
    if (ticker == null) return;
    if (isPlaying) {
      setTimer(ticker);
    }
  }

  /// Plays the appropriate sound for the current tick
  Future<void> playSound() async {
    // Ensure players have the correct volume
    if (player1.volume == 0 || player2.volume == 0) {
      Future.wait([
       player1.setVolume(1.0),
       player2.setVolume(1.0)
      ]);
    }
    if (beatIndicator.isEmpty) return;
    if (totalBeat > 12) {
      if (totalTick == 1) {
         playBeat(firstBeat, player1);
      } else if (totalTick <= totalBeat) {
         playBeat(secondBeat, player2);
        if (totalTick == totalBeat) {
          totalTick = 0;
        }
      }
    } else {
      if (totalTick == 1) {
        // Optionally play accented beat
      } else if (totalTick <= totalBeat) {
        // Optionally play regular beat
        if (totalTick == totalBeat) {
          totalTick = 0;
        }
      }

      if (beatIndicator[totalTick].isAccentedBeat) {
         playBeat(firstBeat, player1);
      } else if (beatIndicator[totalTick].isPlanBeat) {
         playBeat(secondBeat, player2);
      }
      // Muted beat: do nothing
    }
    if(beatIndicator.length>totalTick){

      totalTick += 1;
    }else{
      totalTick=beatIndicator.length-1;
    }
    notifyListeners();
  }

  /// Plays a specific beat sound using the given player
  Future<void> playBeat(String beat, AudioPlayer player) async {
    if (kIsWeb) {
      playWebMetronomeSound(beat, jhgMetronomeVol);
    } else {
      await Future.wait([
        player.seek(Duration.zero),
        player.load(),
        player.setVolume(jhgMetronomeVol),
        player.play(),
      ]);
    }
  }
}
