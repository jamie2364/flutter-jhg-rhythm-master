import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:reg_page/reg_page.dart';
import 'package:rhythm_master/models/sound_model.dart';
import 'package:rhythm_master/services/local_db.dart';
import 'package:rhythm_master/utils/app_strings.dart';
import 'package:rhythm_master/utils/app_utils.dart';
import '../utils/app_assets.dart';

//The SpeedProvider class manages the functionality of a speed trainer,
// including BPM, intervals, and audio playback.

class SpeedProvider extends ChangeNotifier {
  // INDICATE SOUND IS PLAYING OR STOP
  bool isPlaying = false;
  // BPM IS BEAT PER MINUTE
  double bpm = 120;
  // Instance of the Player
  final player1 = AudioPlayer();
  final player2 = AudioPlayer();  
  // TIMER IS  BPM
  Timer? _timer;

  // START TEMPO VALUES
  double startTempo = 120;
  double startTempoMin = 1;
  double startTempoMax = 300;

  // TARGET TEMPO VALUES
  double targetTempo = 180;
  double targetTempoMin = 1;
  double targetTempoMax = 300;

  // INTERVAL VALUES
  // BPM SPEED WILL CHANGE ACCORDING TO INTERVAL
  int interval = 10;
  int minInterval = 1;
  int maxInterval = 120;

  // BAR IS BEAT PER BPM
  int bar = 2;
  int minBar = 1;
  int maxBar = 60;
  int defaultBar = 2;
  int defaultInterval = 1;
  int sliderInterval = 1;
  int totalBeats = 4;

  final player = AudioPlayer();

  String soundName = AppStrings.logic;
  String firstBeat = AppAssets.logic1Sound;
  String secondBeat = AppAssets.logic2Sound;
  String? defaultBeatValue;
  double gafInterval = 1;

  // Initialize  animation controller
  initializeAnimationController() async {
    Future.delayed(Duration.zero, () async {
      setSpeedTrainerDefaultValue();
    });
  }

  Future<void> preloadSounds() async {
    Future.wait([
     player1.setVolume(0),
     player2.setVolume(0),
    ]);

    var directory1 = !kIsWeb ? Utils.getAsset(firstBeat) : AppUtils.setWebAsset(firstBeat);
    var directory2 = !kIsWeb ? Utils.getAsset(secondBeat) : AppUtils.setWebAsset(secondBeat);

    Future.wait([
      player1.setFilePath(directory1.path, preload: true),
      player2.setFilePath(directory2.path, preload: true)
    ]);

  }

  Future<void> setSpeedTrainerDefaultValue() async {
    // Fetch default values from SharedPreferences concurrently using Future.wait
    final results = await Future.wait([
      SharedPref.getStoreSpeedTrainerDefaultSound,
      SharedPref.getSpeedTrainerDefaultValue,
      SharedPref.getSpeedTrainerDefaultInterval,
    ]);

    final defSound = results[0] as int?;
    final defValue = results[1] as String?;
    final defSpeedInterval = results[2] as double?;

    // Set default values
    gafInterval = defSpeedInterval ?? 1;
    defaultBeatValue = defValue ?? "4/4";

    // Set sound-related values based on the defSound
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

    // Set beats duration and preload sounds
    getBeatsDuration(defaultBeatValue!);
    await preloadSounds();

    // Notify listeners
    notifyListeners();
  }


  // TOTAL TICK IS USED TO IDENTIFY BEAT AUDIO
  // TWO TYPE OF AUDIO TICK / TAP
  int totalTick = 0;

  getBeatsDuration(String value) {
    List beatValue = value.split("/");
    int beatN = int.parse(beatValue[0]);
    int beatD = int.parse(beatValue[1]);
    print("Beat Numerator : $beatN");
    print("Beat Denominator : $beatD");
    totalBeats = beatN;
    Map<int, int> beatDurationMap = {
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

  // Clear speed trainer settings
  clearSpeedTrainer(bool isNotify) {
    if(_timer != null) {
      _timer!.cancel();
    }
    isPlaying = false;
    bpm = 120;
    startTempo = 120;
    targetTempo = 180;
    interval = defaultInterval;
    bar = defaultBar;
    totalTick = 0;
    barCounter = 0;
    if (isNotify == true) {
      notifyListeners();
    }
  }

  // SET START TEMPO RANGE OF SLIDER
  setStartTempo(double value) {
    startTempo = value;
    bpm = startTempo;
    barCounter = 0;
    totalTick = 0;
    firstTime = true;
    notifyListeners();
    if(isPlaying == true) {
      setTimer();
    }
  }

  // SET TARGET RANGE OF SLIDER
  setTargetTempo(double value) {
    targetTempo = value;
    barCounter = 0;
    totalTick = 0;
    firstTime = true;
    notifyListeners();
    if (isPlaying) {setTimer();}
  }

  // INTERVAL
  void onChangedInterval(int newValue) {
    interval = newValue;
    notifyListeners();
    if (isPlaying) {setTimer();}
  }

  onChangedBar(int newValue) {
    bar = newValue;
    // Reset critical counters and flags
    totalTick = 0;
    barCounter = 0;
    firstTime = true; // Important to reset the first-time flag
    notifyListeners();
    if (isPlaying) {
      setTimer(); // Re-set the timer to adapt to the new bar setting
    }
  }

  onChangedDefaultBar(int newValue) {
    defaultBar = newValue;
    notifyListeners();
  }

  onChangedDefaultInterval(int newValue) {
    defaultInterval = newValue;
    notifyListeners();
  }

  onChangedSliderInterval(int newValue) {
    sliderInterval = newValue;
    notifyListeners();
  }

  void startStop() {
    totalTick = 0;
    barCounter = 0;
    firstTime = true; // Reset so it knows to increase BPM again
    // bpm = startTempo; // Reset BPM to the starting tempo

    if (isPlaying) {
      if (_timer != null) {
        _timer!.cancel(); // Stop the current timer
      }
    } else {
      setTimer(); // Restart with updated settings
    }

    isPlaying = !isPlaying;
    notifyListeners();
  }

  int timeStamp = 60000;

  ///===========
  setTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer.periodic(
      Duration(milliseconds: (timeStamp / bpm).round()),
      (Timer timer) async {
        if (targetTempo + interval > bpm) {
          playSound();
        } else {
          _timer!.cancel();
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

  // Bar counter and first-time flags
  int barCounter = 0;
  bool firstTime = true;

  Future playSound() async {
    if(player1.volume == 0 || player2.volume == 0){
      player1.setVolume(1.0);
      player2.setVolume(1.0);
    }
    barCounter = barCounter + 1;
    totalTick = totalTick + 1;

    if (totalTick == 1) {
      // Adjust this check to handle the barCounter correctly
      bool check = firstTime == true
          ? barCounter - 1 == bar * totalBeats
          : barCounter == bar * totalBeats;

      if (check == true) {
        bpm = bpm + interval;
        barCounter = 0;
        firstTime = false;
        notifyListeners();
        setTimer();
      }
      // If we've reached the target tempo, stop increasing
      if (bpm >= targetTempo + bar * interval) return;
        playBeat1();
    } else {
      if (totalTick < totalBeats) {
        playBeat2();
      } else {
        totalTick = 0;
        playBeat2();
      }
    }
  }

  playBeat1() {
    player1.seek(Duration.zero);
    player1.load();
    player1.play();
  }

  playBeat2() {
    player2.seek(Duration.zero);
    player2.load();
    player2.play();
  }



  void incrementTempo(int interval) {
    startTempo = adjustTempo(startTempo + interval, targetTempo);
    bpm = startTempo;
    notifyListeners();
  }

  void decrementTempo(int interval) {

    startTempo = adjustTempo(startTempo - interval, targetTempo);
    bpm = startTempo;
    notifyListeners();
  }

  void incrementTargetTempo(int interval) {
    targetTempo = adjustTempo(targetTempo + interval, 300);
    notifyListeners();
  }

  void decrementTargetTempo(int interval) {

    targetTempo = adjustTempo(targetTempo - interval, 300);


    notifyListeners();
  }

// Helper function to ensure tempo stays within a valid range
  double adjustTempo(double newTempo, double limit) {

    if (newTempo > limit) {
      return limit;
    } else if (newTempo < 1) {
      return 1;
    }
    return newTempo;
  }


}
