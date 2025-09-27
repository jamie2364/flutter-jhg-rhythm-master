import 'dart:io';

import 'package:flutter/foundation.dart';

import 'app_strings.dart';

class AppConstants {
  AppConstants._();

  static const String androidBuildId =
      'com.jamieharrisonguitar.jhg_rhythm_toolkit';
  static const String iOSBuildId = 'com.jamieharrisonguitar.jhg-rhythm-toolkit';

  static String get monthlySubscription => kIsWeb
      ? 'web'
      : Platform.isAndroid
          ? 'jhgrhythmtoolkit.monthly'
          : 'com.jamieharrisonguitar.rhythmtoolkit.monthly';

  static String get yearlySubscription => kIsWeb
      ? 'web'
      : Platform.isAndroid
          ? 'jhgrhythmtoolkit.annual'
          : 'com.jamieharrisonguitar.rhythmtoolkit.annual';

  static String get nativeBannerAdId => kIsWeb
      ? ''
      : Platform.isAndroid
          ? 'ca-app-pub-8243857750402094/5169233790'
          : 'ca-app-pub-8243857750402094/5635690548';

  static String get interstitialAdId => kIsWeb
      ? ''
      : Platform.isAndroid
          ? 'ca-app-pub-8243857750402094/4586332752'
          : 'ca-app-pub-8243857750402094/8916907116';

  static String get bannerAdId => kIsWeb
      ? ''
      : Platform.isAndroid
          ? 'ca-app-pub-8243857750402094/8740263747'
          : 'ca-app-pub-8243857750402094/4008974952';

  static List<String> get getFeaturesList => [
        'Precise Metronome for accurate timing and rhythm',
        'Tap Tempo for 1uick and easy beat detection',
        'Speed Trainer to improve playing speed and accuracy',
        'Ad free experience',
        'Early access to new features',
        'Premium support',
      ];

  // List on buttons, Metronome | Tap Tempo | Speed Trainer
  static List<String> buttonList = [
    AppStrings.metronome,
    AppStrings.tapTempo,
    AppStrings.speedTrainer
  ];
  static List<String> buttonsDesc = [
    AppStrings.metronomeDesc,
    AppStrings.tapTempoDesc,
    AppStrings.speedTrainerDesc
  ];
}
