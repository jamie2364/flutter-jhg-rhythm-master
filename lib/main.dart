import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:provider/provider.dart';
import 'package:reg_page/reg_page.dart';
import 'package:rhythm_master/utils/app_strings.dart';
import 'package:rhythm_master/utils/app_constants.dart';
import 'package:rhythm_master/providers/home_provider.dart';
import 'package:rhythm_master/providers/metro_provider.dart';
import 'package:rhythm_master/providers/setting_provider.dart';
import 'package:rhythm_master/providers/speed_provider.dart';
import 'package:rhythm_master/providers/tap_temp_provider.dart';
import 'package:rhythm_master/views/screens/home_screen.dart';

var isFreePlan = false;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) await StringsDownloadService().init();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.light,
  ));
  JHGAdsHelper().init();
  JHGAdsHelper().addATestDevice("");
  runApp(const MyApp());
}

final navKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparent status bar
      statusBarBrightness: Brightness.dark, // Dark text for status bar
    ));

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TapTempoProvider>(create: (context) => TapTempoProvider()),
        ChangeNotifierProvider<SpeedProvider>(create: (context) => SpeedProvider()),
        ChangeNotifierProvider<MetroProvider>(create: (context) => MetroProvider()),
        ChangeNotifierProvider<SettingProvider>(create: (context) => SettingProvider()),
        ChangeNotifierProvider<HomeProvider>(create: (context) => HomeProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navKey,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
            child: child!,
          );
        },
        debugShowCheckedModeBanner: false,
        title: AppStrings.appName,
        theme: JHGTheme.themeData.copyWith(
          scrollbarTheme: ScrollbarThemeData(
            thumbColor: WidgetStateProperty.all(JHGColors.whiteGrey),
          ),
        ),
        home: kIsWeb ? const HomeScreen() : SplashScreen(
                yearlySubscriptionId: AppConstants.yearlySubscription,
                monthlySubscriptionId: AppConstants.monthlySubscription,
                featuresList: AppConstants.getFeaturesList,
                nextPage: () => const HomeScreen(),
                appName: AppStrings.appName,
                navKey: navKey,
              ),
      ),
    );
  }
}
