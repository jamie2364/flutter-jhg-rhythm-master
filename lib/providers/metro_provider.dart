import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:reg_page/reg_page.dart';
import 'package:rhythm_master/utils/app_strings.dart';
import 'package:rhythm_master/utils/app_utils.dart';
import 'package:rhythm_master/models/sound_model.dart';
import 'package:rhythm_master/services/local_db.dart';

import '../models/beat_indicator_model.dart';
import '../utils/app_assets.dart';

//The MetroProvider class is responsible for managing the metronome functionality,
//controlling BPM, animation, and sound playback.


class MetroProvider extends ChangeNotifier {

  List <BeatIndicator> beatIndicator = [];

  createBeatIndicatorList(){

    int listLength = totalBeat;

    if(listLength > 6){
      setBeatIndicatorState(true);
      return;
    }

    setBeatIndicatorState(false);
    beatIndicator = List.generate(listLength, (index) {
         bool isAccented = index == 0 ? true : false;
         bool isMutedBeat = false;
         bool isPlanBeat = index == 0 ? false : true;
        return BeatIndicator(
            isAccentedBeat: isAccented,
            isMutedBeat: isMutedBeat,
            isPlanBeat: isPlanBeat);

    });
    notifyListeners();

  }


  updateBeatIndicatorList(int selectedIndex){

        if( beatIndicator[selectedIndex].isAccentedBeat == true){

          beatIndicator[selectedIndex].isAccentedBeat = false;
          beatIndicator[selectedIndex].isPlanBeat = true;
          beatIndicator[selectedIndex].isMutedBeat = false;

        }else if(beatIndicator[selectedIndex].isPlanBeat == true){

          beatIndicator[selectedIndex].isAccentedBeat = false;
          beatIndicator[selectedIndex].isPlanBeat = false;
          beatIndicator[selectedIndex].isMutedBeat = true;

        }
        else if(beatIndicator[selectedIndex].isMutedBeat == true){
          beatIndicator[selectedIndex].isAccentedBeat = true;
          beatIndicator[selectedIndex].isPlanBeat = false;
          beatIndicator[selectedIndex].isMutedBeat = false;

        }

    notifyListeners();

  }

  bool hideBeatIndicator  = false;
  setBeatIndicatorState(bool state){
    hideBeatIndicator = state;
    notifyListeners();
  }
  // Custom value selection
  int beatNumerator = 2;
  int beatDenominator = 2;

  // initial values of BPM
  Timer? bpmContinuousTimer;
  double bpm = 120;
  double bpmMin = 1.0;
  double bpmMax = 300.0;

  // Initial value of slider
  // double sliderMin = 1.0;
  // double sliderMax = 300.0;

  // List of Beat buttons
  List<String> tapButtonList = ['4/4', '3/4', '6/8', '12/8'];

  // Position of the slider
  double position = 0;
  int totalBeat = 4;
  int totalTick = 0;
  bool isPlaying = false;

  // Animation controller values
  AnimationController? controller;
  Animation<double>? animation;

  // Instance of the Player

  int? selectedIndex;

  double timeStamp = 0;

  double? defaultBPM;
  int? defaultSound;
  int? defaultTiming;
  String? defaultBeatValue;

  // Instance of the Player
  final player1 = AudioPlayer();
  final player2 = AudioPlayer();

  bool firstTime = true;
  bool isRepeat = true;
  Timer? timer;

  // Set selected sound
  String soundName = AppStrings.logic;
  String firstBeat = AppAssets.logic1Sound;
  String secondBeat = AppAssets.logic2Sound;
  int selectedButton = 0;

  clearBottomSheetBeats() {
    beatNumerator = 2;
    beatDenominator = 2;
    notifyListeners();
  }

  Future<void> preloadSounds() async {
    Future.wait([ player1.setVolume(0),player2.setVolume(0)]);
    var directory1 = !kIsWeb ? Utils.getAsset(firstBeat)  : AppUtils.setWebAsset(firstBeat);
    var directory2 = !kIsWeb ? Utils.getAsset(secondBeat) : AppUtils.setWebAsset(secondBeat);
    Future.wait([
     player1.setFilePath(directory1.path, preload: true),
     player2.setFilePath(directory2.path, preload: true)
    ]);
  }


  incrementBeatNumerator() {
    if (beatNumerator < 96) {
      beatNumerator = beatNumerator + 1;
      notifyListeners();
    }
  }

  decrementBeatNumerator() {
    if (beatNumerator > 2) {
      beatNumerator = beatNumerator - 1;
      notifyListeners();
    }
  }

  incrementBeatDenominator() {
    if (beatDenominator < 64) {
      beatDenominator = beatDenominator + beatDenominator;
      notifyListeners();
    }
  }

  decrementBeatDenominator() {
    if (beatDenominator > 2) {
      beatDenominator = beatDenominator - beatDenominator ~/ 2;
      notifyListeners();
    }
  }

  String? customBeatValue;

  setValueOfBottomSheet(TickerProviderStateMixin ticker) {
    selectedButton = 4;
    String value = "${beatNumerator}/${beatDenominator}";
    customBeatValue = value;
    notifyListeners();
    getBeatsDuration(value, selectedButton);
    if (isPlaying) {
      setTimer(ticker);
    }
  }

  setTimeStamp(int value) {
    timeStamp = 240000 / value;
    notifyListeners();
  }

  double gafInterval = 1;

  // Initialize  animation controller
  initializeAnimationController(
    TickerProviderStateMixin ticker,
  ) async {
    if (timer != null) {
      timer!.cancel();
    }
    // calling sound list to add sound to sound list

    controller = AnimationController(
      duration: Duration(milliseconds: (30000 / bpm).round()),
      vsync: ticker,
    );

    animation = Tween<double>(begin: 0, end: 1).animate(controller!);
    controller!.repeat(reverse: true);
    controller!.stop();
    // await preloadSounds();
    Future.delayed(Duration.zero, () async {
      setMetronomeDefaultValue();
    });
  }

  Future<void> setMetronomeDefaultValue() async {
    // Fetch all default values concurrently
    final results = await Future.wait([
      SharedPref.getDefaultBPM,
      SharedPref.getDefaultSound,
      SharedPref.getDefaultTiming,
      SharedPref.getMetronomeDefaultValue,
      SharedPref.getMetronomeDefaultInterval,
    ]);

    // Extract results
    double? defBPM = results[0] as double?;
    int? defSound = results[1] as int?;
    int? defTiming = results[2] as int?;
    String? defValue = results[3] as String?;
    double? defMetroInterval = results[4] as double?;

    // Assign default values
    defaultBPM = defBPM ?? 120;
    defaultSound = defSound ?? 0;
    defaultTiming = defTiming ?? 0;
    defaultBeatValue = defValue ?? "4/4";
    gafInterval = defMetroInterval ?? 1;

    // Set UI-related properties
    selectedButton = defaultTiming!;
    bpm = defaultBPM!;
    position = 0;
    totalTick = 0;
    isPlaying = false;

    // Configure beat and sound settings
    getBeatsDuration(defaultBeatValue!, selectedButton);
    soundName = soundList[ selectedIndex ?? defaultSound!].name!;
    firstBeat = soundList[ selectedIndex ?? defaultSound!].beat1!;
    secondBeat = soundList[ selectedIndex ?? defaultSound!].beat2!;

    // Preload sounds
    await preloadSounds();


    // Notify listeners
    notifyListeners();
  }


  // Dispose controller if off the page
  Future<void> disposeController() async {
    timer?.cancel();
    bpmContinuousTimer?.cancel();
    isPlaying = false;
    controller?.dispose();
    controller = null;
  }

  // Clear metronome
  void clearMetronome() {
    timer?.cancel();
    if (controller != null) {
      animation = Tween<double>(begin: 0, end: 1).animate(controller!);
      controller!.reset();
    }
    setMetronomeDefaultValue();
    notifyListeners();
  }

  // Reset metronome custom bottom sheet
  void resetMetronomeCustomBottomSheet() {
    beatNumerator = 2;
    beatDenominator = 2;
    notifyListeners();
  }


  // Set position of the slider
  // Setting position, BPM, and notifying listeners
  setPosition(double value, TickerProviderStateMixin ticker) {
    position = value;
    bpm = value;
    totalTick = 0;
    notifyListeners();
    if (isPlaying == true) {
      setTimer(ticker);
    }
  }


  void adjustBpm(TickerProviderStateMixin ticker, int increment) {
    double newBpm =  bpm + increment;
    if (newBpm >= bpmMin && newBpm <= bpmMax) {
      totalTick = 0;
      bpm = newBpm;
      notifyListeners();
      if (isPlaying) {
        setTimer(ticker);
      }
    }
  }

  void startContinuousBpmAdjustment(TickerProviderStateMixin ticker, int increment) {
    bpmContinuousTimer?.cancel();
    bpmContinuousTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      adjustBpm(ticker, increment);
    });
  }

// Public methods for increasing/decreasing BPM
  void increaseBpm(TickerProviderStateMixin ticker) => adjustBpm(ticker, 1);
  void decreaseBpm(TickerProviderStateMixin ticker) => adjustBpm(ticker, -1);

// Public methods for continuous adjustment
  void continuousIncreaseBpm(TickerProviderStateMixin ticker) => startContinuousBpmAdjustment(ticker, 1);
  void continuousDecreaseBpm(TickerProviderStateMixin ticker) => startContinuousBpmAdjustment(ticker, -1);


  // Start/stop the metronome
  // Toggling between start and stop states and notifying listeners

  Future<void> startStop(TickerProviderStateMixin ticker) async {
    firstTime = true;
    totalTick = 0;
    if (isPlaying) {
      controller!.reset();
      animation = Tween<double>(begin: 0, end: 1).animate(controller!);
      if (timer != null) {
        timer!.cancel();
      }
    } else {
      setTimer(ticker);
    }
    isPlaying = !isPlaying;
    notifyListeners();
  }

// Define a flag to prevent multiple calls within a very short interval
  ///=================================
  //Set timer base on the BPM
  setTimer(TickerProviderStateMixin ticker) async {
    //player.setVolume(1.0);
    // dispose the previous timer adn add new one base on BPM
    // setMetronomeDefaultValue();
    totalTick = 0;
    firstTime = true;
    controller!.reset();
    controller!.dispose();

    int timerInterval = (timeStamp / bpm).round();

    controller = AnimationController(
      duration: Duration(milliseconds: timerInterval),
      vsync: ticker,
    );

    animation = Tween<double>(begin: 0, end: 1).animate(controller!);
    if (timer != null) {
      timer!.cancel();
    }

    timer = Timer.periodic(Duration(milliseconds: timerInterval), (timer) {
      playSound();
    });

    controller!.repeat(reverse: true);
    // Listen to timer to animate stalk and play sound
    controller!.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        if (firstTime == true) {
          firstTime = false;
        }
      }
      if (status == AnimationStatus.reverse) {
        if (firstTime == true) {
          animation = Tween<double>(begin: -1, end: 1).animate(controller!);
          controller!.repeat(
            reverse: true,
          );
        }
      }
    });
  }

  ///===================================
  // Set beats based on the selected button
  // Setting total beats based on the selected button and notifying listeners

  getBeatsDuration(String value, int buttonIndex) {
    List beatValue = value.split("/");

    int beatN = int.parse(beatValue[0]);
    int beatD = int.parse(beatValue[1]);

    print("Beat Numerator : $beatN");
    print("Beat Denomenator : $beatD");

    totalBeat = beatN;

    Map<int,double> beatDurations = {
      2: 120000,
      4: 60000,
      8: 30000,
      16: 15000,
      32: 7500,
      64: 3750,
    };

    // Get the timestamp or default to 60000 (for unsupported beat denominators)
    timeStamp = beatDurations[beatD] ?? 60000;

    if (selectedButton == 4) {
      customBeatValue = value;
      beatNumerator = beatN;
      beatDenominator = beatD;
    }
    notifyListeners();
  }

  setBeats(
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

  // Setting selected sound and notifying listeners
  setSound(
      {required TickerProviderStateMixin? ticker,
      required String name,
      required String beat1,
      required beat2,
      required int index}) {
    selectedIndex = index;
    soundName = name;
    firstBeat = beat1;
    secondBeat = beat2;
    totalTick = 0;
    notifyListeners();
    if (ticker == null) return;
    if (isPlaying == true) {
      setTimer(ticker);
    }
  }



// Play sound based on the metronome ticks
  Future<void> playSound() async {


    // Ensure players have the correct volume
    if (player1.volume == 0 || player2.volume == 0) {
      player1.setVolume(1.0);
      player2.setVolume(1.0);
    }


    // Determine which beat to play
    if (totalTick == 1) {
      //playBeat(firstBeat, player1);
    } else if (totalTick <= totalBeat) {
     // playBeat(secondBeat, player2);
      // Reset totalTick if the beat cycle is complete
      if (totalTick == totalBeat) {
        totalTick = 0;
      }
    }

    if(beatIndicator[totalTick].isAccentedBeat == true){
      playBeat(firstBeat, player1);
    }else if(beatIndicator[totalTick].isPlanBeat == true){
      playBeat(secondBeat, player2);
    } else if(beatIndicator[totalTick].isMutedBeat == true){

    }

    totalTick += 1;
    notifyListeners();
  }

 // Play the specified beat using the given audio player
  Future<void> playBeat(String beat, AudioPlayer player) async {
    player.seek(Duration.zero);
    await player.load();
    player.play();
  }


}
