import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:provider/provider.dart';
import 'package:rhythm_master/providers/metro_provider.dart';
import 'package:rhythm_master/utils/app_assets.dart';
import 'package:rhythm_master/utils/app_colors.dart';
import 'package:rhythm_master/views/extension/int_extension.dart';
import 'package:rhythm_master/views/extension/widget_extension.dart';
import 'package:rhythm_master/views/widgets/custom_selection_bottomsheet.dart';

import '../../models/beat_indicator_model.dart';

class MetroView extends StatefulWidget {
  const MetroView({super.key});

  @override
  State<MetroView> createState() => _MetroViewState();
}

class _MetroViewState extends State<MetroView> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    final metroProvider = Provider.of<MetroProvider>(context, listen: false);
    metroProvider.initializeAnimationController(this);
  }

  MetroProvider? metroProvider;

  @override
  void didChangeDependencies() {
    metroProvider = Provider.of<MetroProvider>(context, listen: false);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    metroProvider!.disposeController();
    //metroProvider!.dispose(); // Dispose the MetroProvider
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //metroProvider?.init();
    bool isTablet = MediaQuery.of(context).size.width < 1100 &&
        MediaQuery.of(context).size.width >= 701 &&
        !kIsWeb;
    final height = MediaQuery.of(context).size.height;
    final metroWidth = isTablet
        ? 450.0.w
        : JHGResponsive.isTablet(context)
            ? 340.0.w
            : 220.0.w;
    final metroHeight = isTablet
        ? 600.0.w
        : kIsWeb
            ? 290.0.h
            : JHGResponsive.isTablet(context)
                ? 470.0.h
                : 308.0.h;

    return Consumer<MetroProvider>(builder: (context, controller, child) {
      final bpm = controller.bpm;
      final bpm2x = controller.bpm * 2;
      return Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    physics: NeverScrollableScrollPhysics(),
                    child: Container(
                      //color: Colors.blue,
                      constraints: BoxConstraints(
                          maxWidth: isTablet
                              ? 780.0.w
                              : JHGResponsive.isTablet(context)
                                  ? 490.0.w
                                  : 345.0.w,
                          minHeight: 200.0.h),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SPACER
                          SizedBox(
                              height: JHGResponsive.isTablet(context)
                                  ? height * 0.095
                                  : height * 0.025),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Button selection 3/3 ....
                              Container(
                                height: isTablet
                                    ? height * 0.6
                                    : JHGResponsive.isTablet(context)
                                        ? height * 0.42
                                        : height * 0.41,
                                width: isTablet ? height * 0.1 : height * 0.08,
                                child: ListView.builder(
                                    physics: AlwaysScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    primary: true,
                                    itemCount:
                                        controller.tapButtonList.length + 1,
                                    shrinkWrap: true,
                                    scrollDirection: Axis.vertical,
                                    itemBuilder: (context, index) {
                                      return MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: () async {
                                              if (index ==
                                                  controller
                                                      .tapButtonList.length) {
                                                controller
                                                    .setMetronomeDefaultValue();
                                                customSelectionBottomSheet(
                                                    context, this);
                                              } else {
                                                controller.setBeats(
                                                    ticker: this,
                                                    index: index,
                                                    indexValue: controller
                                                        .tapButtonList[index]);
                                              }
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: height * 0.009),
                                              child: Container(
                                                height: isTablet
                                                    ? height * 0.1
                                                    : height * 0.08,
                                                width: isTablet
                                                    ? height * 0.1
                                                    : height * 0.08,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: controller
                                                              .selectedButton ==
                                                          index
                                                      ? AppColors.greySecondary
                                                      : AppColors.greyPrimary,
                                                ),
                                                child: Column(
                                                  mainAxisAlignment: (index ==
                                                          4)
                                                      ? MainAxisAlignment.start
                                                      : MainAxisAlignment
                                                          .center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    (index == 4)
                                                        ? JHGIconButton(
                                                            size: JHGResponsive
                                                                    .isTablet(
                                                                        context)
                                                                ? 25
                                                                : 20,
                                                            iconData:
                                                                Icons.edit,
                                                            iconColor:
                                                                JHGColors.white,
                                                          )
                                                            .paddingOnly(
                                                                top: 8,
                                                                right: 8,
                                                                bottom: 0)
                                                            .align(Alignment
                                                                .topRight)
                                                        : SizedBox(),
                                                    Text(
                                                      (index ==
                                                                  controller
                                                                      .tapButtonList
                                                                      .length &&
                                                              controller
                                                                      .customBeatValue ==
                                                                  null)
                                                          ? "Custom"
                                                          : (index ==
                                                                      controller
                                                                          .tapButtonList
                                                                          .length &&
                                                                  controller
                                                                          .customBeatValue !=
                                                                      null)
                                                              ? controller
                                                                  .customBeatValue!
                                                              : controller
                                                                      .tapButtonList[
                                                                  index],
                                                      style: JHGTextStyles
                                                          .subLabelStyle
                                                          .copyWith(
                                                        color: AppColors
                                                            .whitePrimary,
                                                        fontSize: (index ==
                                                                    controller
                                                                        .tapButtonList
                                                                        .length &&
                                                                controller
                                                                        .customBeatValue ==
                                                                    null)
                                                            ? 12
                                                            : 18,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ));
                                    }),
                              ),

                              // SPACER

                              // Metronome
                              Container(
                                // color: Colors.red,
                                alignment: Alignment.center,
                                height: metroHeight,
                                width: metroWidth,
                                child: Stack(
                                  children: [
                                    // Metronome
                                    Container(
                                      //color: Colors.green,
                                      height: metroHeight,
                                      width: metroWidth,
                                      child: Image.asset(
                                        AppAssets.metronome,
                                        height: metroHeight,
                                        width: metroWidth,
                                        fit: BoxFit.fill,
                                      ),
                                    ),

                                    // Stalk
                                    Positioned(
                                      top: JHGResponsive.isTablet(context)
                                          ? 62
                                          : 40,
                                      left: 1,
                                      right: 1,
                                      // right: 20,
                                      child: Container(
                                        //color: Colors.yellow,
                                        height: kIsWeb
                                            ? 160
                                            : JHGResponsive.isTablet(context)
                                                ? 270
                                                : 180,
                                        //width: 100,
                                        alignment: Alignment.bottomCenter,

                                        /// =========== animation null
                                        child: controller.animation == null
                                            ? SizedBox()
                                            : AnimatedBuilder(
                                                animation:
                                                    controller.animation!,
                                                builder: (context, child) {
                                                  //You can customize the translation and rotation values
                                                  double translationValue = 0 *
                                                      controller
                                                          .animation!.value;
                                                  double rotationValue = 180 *
                                                      controller
                                                          .animation!.value;
                                                  //

                                                  return Transform(
                                                    alignment:
                                                        Alignment.bottomCenter,
                                                    transform:
                                                        Matrix4.identity()
                                                          ..translate(
                                                              translationValue,
                                                              0.0)
                                                          ..rotateZ(
                                                              rotationValue *
                                                                  0.0034533),
                                                    // Convert degrees to radians
                                                    child: Stack(
                                                      children: [
                                                        Container(
                                                          //color: Colors.green,
                                                          height: metroHeight,
                                                          width: JHGResponsive
                                                                  .isTablet(
                                                                      context)
                                                              ? 45
                                                              : 37,
                                                          alignment:
                                                              Alignment.center,
                                                          child: Image.asset(
                                                            AppAssets.stalk,
                                                            height: metroHeight,
                                                            width: JHGResponsive
                                                                    .isMobile(
                                                                        context)
                                                                ? 11
                                                                : JHGResponsive
                                                                        .isTablet(
                                                                            context)
                                                                    ? 15
                                                                    : 9,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                        //slider
                                                        Positioned(
                                                          top: kIsWeb
                                                              ? bpm <= 250
                                                                  ? (bpm *
                                                                      (bpm2x -
                                                                          40) *
                                                                      0.0010)
                                                                  : (bpm *
                                                                      (bpm2x -
                                                                          175) *
                                                                      0.0008)
                                                              : JHGResponsive
                                                                      .isTablet(
                                                                          context)
                                                                  ? bpm <= 250
                                                                      ? (bpm *
                                                                          (bpm2x -
                                                                              65) *
                                                                          0.0010)
                                                                      : (bpm *
                                                                          (bpm2x -
                                                                              220) *
                                                                          0.0016)
                                                                  : bpm <= 250
                                                                      ? (bpm *
                                                                          (bpm2x -
                                                                              50) *
                                                                          0.0010)
                                                                      : (bpm *
                                                                          (bpm2x -
                                                                              195) *
                                                                          0.0010),
                                                          left: 1,
                                                          right: 1,
                                                          child: Image.asset(
                                                            AppAssets.slider,
                                                            height: JHGResponsive
                                                                    .isTablet(
                                                                        context)
                                                                ? 55
                                                                : 37,
                                                            width: JHGResponsive
                                                                    .isTablet(
                                                                        context)
                                                                ? 45
                                                                : 37,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                    ),

                                    //Slider wood
                                    Positioned(
                                      top: kIsWeb
                                          ? 76.0
                                          : JHGResponsive.isTablet(context)
                                              ? 195.0.h
                                              : 88.0.h,
                                      left: 2,
                                      child: Container(
                                        height: 260.0,
                                        width: metroWidth,
                                        alignment: Alignment.bottomCenter,
                                        child: Image.asset(
                                          AppAssets.metronomeBottom,
                                          height: metroHeight,
                                          width: JHGResponsive.isTablet(context)
                                              ? 280
                                              : 203,
                                        ),
                                      ),
                                    ),

                                    // Slider up down
                                    Positioned(
                                      left: 1,
                                      right: 1,
                                      top: 39,
                                      child: Container(
                                        alignment: Alignment.topCenter,
                                        height: 250,
                                        //162,
                                        color: Colors.transparent,
                                        child: RotatedBox(
                                          quarterTurns: 1,
                                          child: Opacity(
                                            opacity: 0,
                                            child: Slider(
                                              divisions: 300,
                                              //300,
                                              activeColor: Colors.transparent,
                                              inactiveColor: Colors.transparent,
                                              thumbColor: Colors.transparent,
                                              value: controller.bpm,
                                              min: 40,
                                              max: 300,
                                              //300,
                                              onChanged: (value) {
                                                controller.setPosition(
                                                    value, this);
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // SPACER

                              Container(
                                // height: height * 0.40,
                                width:
                                    isTablet ? height * 0.022 : height * 0.022,
                                child: controller.hideBeatIndicator
                                    ? SizedBox()
                                    : ListView.builder(
                                        physics:
                                            AlwaysScrollableScrollPhysics(),
                                        padding: EdgeInsets.zero,
                                        primary: true,
                                        itemCount:
                                            controller.beatIndicator.length,
                                        shrinkWrap: true,
                                        scrollDirection: Axis.vertical,
                                        itemBuilder: (context, index) {
                                          final BeatIndicator beatIndicator =
                                              controller.beatIndicator[index];
                                          return MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: GestureDetector(
                                                onTap: () async {
                                                  controller
                                                      .updateBeatIndicatorList(
                                                          index);
                                                },
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: controller
                                                                  .beatIndicator
                                                                  .length >
                                                              6
                                                          ? isTablet
                                                              ? height * 0.01
                                                              : height * 0.005
                                                          : isTablet
                                                              ? height * 0.02
                                                              : height * 0.014),
                                                  child: Container(
                                                    height: height * 0.022,
                                                    width: height * 0.022,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        width: 2,
                                                        color: beatIndicator
                                                                .isAccentedBeat
                                                            ? AppColors
                                                                .redPrimary
                                                            : beatIndicator
                                                                    .isPlanBeat
                                                                ? AppColors
                                                                    .greySecondary
                                                                : AppColors
                                                                    .greyPrimary,
                                                      ),
                                                      color: controller.totalTick -
                                                                      1 ==
                                                                  index &&
                                                              beatIndicator
                                                                  .isAccentedBeat
                                                          ? AppColors.redPrimary
                                                          : controller.totalTick -
                                                                          1 ==
                                                                      index &&
                                                                  beatIndicator
                                                                      .isPlanBeat
                                                              ? AppColors
                                                                  .greySecondary
                                                              : AppColors
                                                                  .greyPrimary,

                                                      // controller.selectedButton ==
                                                      //     index
                                                      //     ? AppColors.greySecondary
                                                      //     : AppColors.greyPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ));
                                        }),
                              ),
                            ],
                          ),
                          // SPACER
                          SizedBox(
                              height: JHGResponsive.isTablet(context)
                                  ? height * 0.04
                                  : height * 0.00),
                          JHGBPMChangeWidget(
                            reverse: true,
                            initialBpmValue: controller.bpm,
                            interval: controller.gafInterval.toInt(),
                            sliderWidth: null,
                            onChanged: (value) {
                              controller.setPosition(value, this);
                            },
                          ),
                          SizedBox(
                            height: height * 0.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Reset button and play pause button
              JHGAppBar(
                isBottom: true,
                isResponsive: true,
                crossAxisAlignment: CrossAxisAlignment.center,
                leadingWidget: JHGResetBtn(
                    enabled: true,
                    onTap: () {
                      controller.clearMetronome();
                    }),
                centerWidget: JHGPlayPauseBtn(
                    isPlaying: controller.isPlaying,
                    onChanged: (val) {
                      controller.startStop(this);
                    }),
              ),
            ],
          ),
          kIsWeb
              ? Positioned(
                  right: -15,
                  bottom: 18.5,
                  child: SizedBox(
                    //color: Colors.red,
                    height: 250,
                    width: 100,
                    child: Center(
                      child: JHGVolumeIndicator(
                        onChange: (val) {
                          print("LLLLLLZZ : $val");
                        },
                        iconBottom: 35,
                        enabled: true,
                        volBottom: 88,
                        volRight: 46,
                      ),
                    ),
                  ),
                )
              : Positioned(
                  right: -35,
                  bottom: 0,
                  child: Container(
                    height: 250,
                    width: 78,
                    child: JHGVolumeIndicator(
                      onChange: (val) {
                        print("LLLLLL : $val");
                        controller.player1.setVolume(val / 100);
                        controller.player2.setVolume(val / 100);
                      },
                      iconBottom: 35,
                      enabled: true,
                      volBottom: 98,
                      volRight: 54,
                    ),
                  ),
                ),
        ],
      );
    });
  }
}
