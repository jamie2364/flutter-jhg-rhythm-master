import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:provider/provider.dart';
import 'package:reg_page/reg_page.dart';
import 'package:rhythm_master/main.dart';
import 'package:rhythm_master/providers/home_provider.dart';
import 'package:rhythm_master/utils/app_colors.dart';
import 'package:rhythm_master/utils/app_constants.dart';
import 'package:rhythm_master/utils/app_strings.dart';
import 'package:rhythm_master/views/extension/int_extension.dart';
import 'package:rhythm_master/views/screens/bpm_view.dart';
import 'package:rhythm_master/views/screens/setting_screen.dart';
import 'package:rhythm_master/views/screens/speed_view.dart';

import 'metro_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // HomeProvider homeProvider = HomeProvider();
  JHGInterstitialAd? interstitialAd;
  DateTime? currentBackPressTime;

  // Set expiry date when user login to the app
  // we will expire user login after 14 days
  setExpiryDate() async {
    DateTime currentDate = DateTime.now();
    DateTime endDate = currentDate.add(const Duration(days: 14));
    await LocalDB.storeEndDate(endDate.toString());
  }

  bool downloadingStatus = true;

  @override
  void initState() {
    setExpiryDate();
    checkToDownloadFile();
    super.initState();
    print('user session ${SplashScreen.session}');
  }

  checkToDownloadFile() async {
    final homeController = Provider.of<HomeProvider>(context, listen: false);
    if (!kIsWeb) {
      downloadingStatus = await StringsDownloadService()
          .isStringsDownloaded(AppStrings.nameOfApp);
      homeController.setDownloadingStatus(downloadingStatus, this);
      LocalDB.getIsFreePlan().then((value) {
        isFreePlan = value;
        if (value) {
          JHGAdsHelper().initializeConsentManager();
          interstitialAd = JHGInterstitialAd(AppConstants.interstitialAdId);
          interstitialAd?.loadAd();
        }
      });
    }
    if (kIsWeb) {
      homeController.setDownloadingStatus(false, this);
      homeController.getUserNameFromRL();
    }
  }

  Future<bool> onWillPop() async {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.redPrimary,
        content: Text(
          "Tap back again to exit app",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.whitePrimary,
          ),
        ),
      ));
      return Future.value(false);
    }
    SystemNavigator.pop();
    Future.delayed(const Duration(milliseconds: 300), () {
      exit(0);
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = MediaQuery.of(context).size.width < 1100 &&
        MediaQuery.of(context).size.width >= 701 &&
        !kIsWeb;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return FutureBuilder(
        future: Provider.of<HomeProvider>(context).initialize(),
        builder: (context, snapshot) {
          return Consumer<HomeProvider>(builder: (context, controller, child) {
            return GestureDetector(
              child: AbsorbPointer(
                absorbing: kIsWeb
                    ? controller.isActive == true
                        ? false
                        : true
                    : false,
                // ignore: deprecated_member_use
                child: WillPopScope(
                  onWillPop: onWillPop,
                  child: Scaffold(
                      backgroundColor: controller.isFirstTimeOpen == true
                          ? Colors.black.withValues(alpha: .7)
                          : null,
                      body: Stack(
                        children: [
                          JHGBody(
                            bodyAppBar: JHGAppBar(
                              isResponsive: true,
                              autoImplyLeading: false,
                              trailingWidget: JHGSettingsButton(
                                  enabled: true,
                                  onTap: () {
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                      builder: (context) {
                                        return const SettingScreen();
                                      },
                                    ));
                                    if (isFreePlan) {
                                      interstitialAd?.showInterstitial(
                                          showAlways: true);
                                    }
                                  }),
                            ),
                            body: Container(
                              // color: Colors.red,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  kIsWeb ? 0.0.height : 10.0.height,
                                  //  SizedBox(height: 10),
                                  //BUTTON SELECTION SECTION
                                  isTablet
                                      ? buildTabView(
                                          height, controller, width, context)
                                      : buildAllView(
                                          context, height, controller, width),

                                  Expanded(
                                    child: controller.selectedButton == 0
                                        ? const MetroView()
                                        : // Now Metronome is first
                                        controller.selectedButton == 1
                                            ? const BpmView()
                                            : // Now Tap Tempo is second
                                            const SpeedView(),
                                  ) // Speed Trainer remains third
                                ],
                              ),
                            ),
                          ),
                          if (controller.isFirstTimeOpen == true)
                            Container(
                              height: double.infinity,
                              width: double.infinity,
                              color: Colors.black.withValues(alpha: .4),
                            ),
                          // TOOLTIPS
                          if (controller.isFirstTimeOpen == true)
                            Positioned(
                              top: height * .22,
                              right: width * .06,
                              child: Container(
                                padding: EdgeInsets.all(width * .035),
                                width: width * .7,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: .7),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Icon(
                                          LucideIcons.info300,
                                          color: AppColors.whitePrimary,
                                          size: 30,
                                        ),
                                        Text(
                                          AppStrings.tooltipsTitle,
                                          style: JHGTextStyles.lrlabelStyle
                                              .copyWith(
                                                  fontStyle: FontStyle.italic),
                                        ),
                                        InkWell(
                                            borderRadius:
                                                BorderRadius.circular(50),
                                            onTap: () {
                                              controller
                                                  .setToNotFirstTimeOpenApp();
                                            },
                                            child: Icon(
                                              LucideIcons.x300,
                                              color: AppColors.whitePrimary,
                                              size: 30,
                                            ))
                                      ],
                                    ),
                                    SizedBox(
                                      height: width * .01,
                                    ),
                                    Text(
                                      AppStrings.tooltipsContent,
                                      style: JHGTextStyles.bodyStyle,
                                      textAlign: TextAlign.center,
                                    )
                                  ],
                                ),
                              ),
                            ),
                        ],
                      )),
                ),
              ),
              onTap: () {
                if (!controller.isActive) {
                  showToast(
                      context: context,
                      message:
                          "Sorry but you do not have an active subscription",
                      isError: true);
                }
              },
            );
          });
        });
  }

  Widget buildAllView(BuildContext context, double height,
      HomeProvider controller, double width) {
    return Container(
      constraints: BoxConstraints(
          maxWidth: kIsWeb
              ? 380.0.w
              : JHGResponsive.isTablet(context)
                  ? 760.0.w
                  : 390.0.w),
      height: height * 0.057,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(AppConstants.buttonList.length, (index) {
            return MouseRegion(
              child: GestureDetector(
                onTap: () async {
                  controller.changeTab(index);
                },
                child: Container(
                  height: height * 0.057,
                  width: kIsWeb ? 120 : width / 3.5,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: controller.selectedButton == index
                          ? AppColors.greySecondary
                          : AppColors.greyPrimary,
                      border: Border.all(color: AppColors.greySecondary)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        AppConstants.buttonList[index],
                        style: JHGTextStyles.labelStyle.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => JHGDialogHelper.showInfoDialog(
                            context: context,
                            title: AppConstants.buttonList[index],
                            description: AppConstants.buttonsDesc[index]),
                        child: Icon(
                          LucideIcons.info300,
                          size: 16,
                          color: JHGColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              cursor: SystemMouseCursors.click,
            );
          })),
    );
  }

  Widget buildTabView(double height, HomeProvider controller, double width,
      BuildContext context) {
    return SizedBox(
      width: 800.0.w,
      height: height * 0.057,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(AppConstants.buttonList.length, (index) {
            return MouseRegion(
              child: GestureDetector(
                onTap: () async {
                  controller.changeTab(index);
                },
                child: Container(
                  height: height * 0.057,
                  width: width / 4,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: controller.selectedButton == index
                          ? AppColors.greySecondary
                          : AppColors.greyPrimary,
                      border: Border.all(color: AppColors.greySecondary)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        AppConstants.buttonList[index],
                        style: JHGTextStyles.labelStyle.copyWith(
                          fontSize: JHGResponsive.isTablet(context) ? 20 : 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => JHGDialogHelper.showInfoDialog(
                            context: context,
                            title: AppConstants.buttonList[index],
                            description: AppConstants.buttonsDesc[index]),
                        child: Icon(
                          LucideIcons.info300,
                          size:
                              JHGResponsive.isTablet(context) ? 28.0.w : 15.0.w,
                          color: JHGColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              cursor: SystemMouseCursors.click,
            );
          })),
    );
  }
}
