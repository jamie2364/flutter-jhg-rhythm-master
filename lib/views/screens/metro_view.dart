import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:provider/provider.dart';
import 'package:reg_page/reg_page.dart';
import 'package:rhythm_master/providers/metro_provider.dart';
import 'package:rhythm_master/utils/app_assets.dart';
import 'package:rhythm_master/utils/app_colors.dart';
import 'package:rhythm_master/views/extension/int_extension.dart';
import 'package:rhythm_master/views/extension/widget_extension.dart';

import '../../models/beat_indicator_model.dart';
import '../widgets/custom_selection_bottomsheet.dart';

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
    final metroWidth = kIsWeb
        ? 220.0.w
        : isTablet
            ? 450.0.w
            : JHGResponsive.isTablet(context)
                ? 340.0.w
                : 220.0.w;
    final metroHeight = isTablet
        ? 600.0.w
        : kIsWeb
            ? 308.0.h
            : JHGResponsive.isTablet(context)
                ? 470.0.h
                : 308.0.h;
    print('is Tablk $isTablet');
    return Consumer<MetroProvider>(builder: (context, provider, child) {
      final bpm = provider.bpm;
      final bpm2x = provider.bpm * 2;

      return Column(
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context)
                  .copyWith(scrollbars: false),
              child: SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                // Metronome widgets Container
                child: Container(
                  // color: Colors.blue,
                  constraints: BoxConstraints(
                      maxWidth: kIsWeb
                          ? 345.0.w
                          : isTablet
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
                        height:
                            //  kIsWeb
                            // ?
                            height * 0.025
                        // : JHGResponsive.isTablet(context)
                        //     ? height * 0.095
                        //     : height * 0.025,
                        ,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Button selection 3/3 ....
                          ButtonsSection(
                            isTablet: isTablet,
                            provider: provider,
                            onButtonTap: (int index) async {
                              if (index == provider.tapButtonList.length) {
                                provider.setMetronomeDefaultValue();
                                customSelectionBottomSheet(context, this,
                                    () {
                                  provider.startStop(this);
                                });
                              } else {
                                provider.setBeats(
                                    ticker: this,
                                    index: index,
                                    indexValue:
                                        provider.tapButtonList[index]);
                              }
                            },
                          ),

                          // SPACER

                          // Metronome
                          MetroUi(
                            metroHeight: metroHeight,
                            metroWidth: metroWidth,
                            bpm: bpm,
                            provider: provider,
                            bpm2x: bpm2x,
                            onChanged: (value) {
                              provider.setPosition(value, this);
                            },
                            isTablet: isTablet,
                          ),

                          // SPACER

                          BeatIndicatorDots(
                              isTablet: isTablet, provider: provider),
                        ],
                      ),
                      // SPACER
                      // SizedBox(
                      //     height: JHGResponsive.isTablet(context)
                      //         ? height * 0.04
                      //         : height * 0.00),
                      JHGBPMChangeWidget(
                        reverse: true,
                        initialBpmValue: provider.bpm,
                        interval: provider.gafInterval.toInt(),
                        sliderWidth: null,
                        onChanged: (value) {
                          provider.setPosition(value, this);
                        },
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
                  provider.clearMetronome();
                }),
            centerWidget: Theme(
              data: ThemeData(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
              ),
              child: JHGPlayPauseBtn(
                  isPlaying: provider.isPlaying,
                  onChanged: (val) {
                    provider.startStop(this);
                  }),
            ),
          ),
        ],
      );
    });
  }
}

class BeatIndicatorDots extends StatelessWidget {
  const BeatIndicatorDots({
    super.key,
    required this.isTablet,
    required this.provider,
  });

  final MetroProvider provider;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final height = Utils.height(context);
    return Container(
      // height: height * 0.40,
      width: isTablet ? height * 0.022 : height * 0.022,
      child: provider.hideBeatIndicator
          ? SizedBox()
          : Theme(
              data: Theme.of(context).copyWith(
                scrollbarTheme: ScrollbarThemeData(
                  thumbColor: MaterialStateProperty.all(Colors.transparent),
                ),
              ),
              child: ListView.builder(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  primary: true,
                  itemCount: provider.beatIndicator.length,
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (context, index) {
                    final BeatIndicator beatIndicator =
                        provider.beatIndicator[index];
                    return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () async {
                            provider.updateBeatIndicatorList(index);
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: provider.beatIndicator.length > 6
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
                                  color: beatIndicator.isAccentedBeat
                                      ? AppColors.redPrimary
                                      : beatIndicator.isPlanBeat
                                          ? AppColors.greySecondary
                                          : AppColors.greyPrimary,
                                ),
                                color: provider.totalTick - 1 == index &&
                                        beatIndicator.isAccentedBeat
                                    ? AppColors.redPrimary
                                    : provider.totalTick - 1 == index &&
                                            beatIndicator.isPlanBeat
                                        ? AppColors.greySecondary
                                        : AppColors.greyPrimary,
                              ),
                            ),
                          ),
                        ));
                  }),
            ),
    );
  }
}

class MetroUi extends StatelessWidget {
  const MetroUi({
    super.key,
    required this.metroHeight,
    required this.metroWidth,
    required this.bpm,
    required this.bpm2x,
    required this.provider,
    required this.onChanged,
    required this.isTablet,
  });

  final bool isTablet;
  final double metroHeight;
  final double metroWidth;
  final double bpm;
  final double bpm2x;
  final MetroProvider provider;
  final void Function(double)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: Colors.red,
      alignment: Alignment.center,
      height: metroHeight,
      width: metroWidth,
      child: Stack(
        children: [
          // Metronome
          Container(
            // color: Colors.green,
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
            // top: isTablet? 80,
            top: kIsWeb
                ? 40
                : isTablet
                    ? 82
                    : 40,
            left: 1,
            right: 1,
            // right: 20,
            child: Container(
              // color: Colors.yellow,
              height: kIsWeb
                  ? 180
                  : isTablet
                      ? 320
                      : 180,
              //width: 100,
              alignment: Alignment.bottomCenter,

              /// =========== animation null
              child: provider.animation == null
                  ? SizedBox()
                  : AnimatedBuilder(
                      animation: provider.animation!,
                      builder: (context, child) {
                        //You can customize the translation and rotation values
                        double translationValue = 0 * provider.animation!.value;
                        double rotationValue = 180 * provider.animation!.value;
                        //

                        return Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.identity()
                            ..translate(translationValue, 0.0)
                            ..rotateZ(rotationValue * 0.0034533),
                          // Convert degrees to radians
                          child: Stack(
                            children: [
                              Container(
                                // color: Colors.green,
                                height: metroHeight,
                                width: kIsWeb
                                    ? 37
                                    : JHGResponsive.isTablet(context)
                                        ? 45
                                        : 37,
                                alignment: Alignment.center,
                                child: Image.asset(
                                  AppAssets.stalk,
                                  height: metroHeight,
                                  width: kIsWeb
                                      ? 11
                                      : JHGResponsive.isMobile(context)
                                          ? 11
                                          : isTablet
                                              ? 18
                                              : 9,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              //slider
                              Positioned(
                                top: kIsWeb
                                    ? bpm <= 250
                                        ? (bpm * (bpm2x - 50) * 0.0010)
                                        : (bpm * (bpm2x - 195) * 0.0010)
                                    : JHGResponsive.isTablet(context)
                                        ? bpm <= 250
                                            ? (bpm * (bpm2x - 65) * 0.0010)
                                            : (bpm * (bpm2x - 220) * 0.0016)
                                        : bpm <= 250
                                            ? (bpm * (bpm2x - 50) * 0.0010)
                                            : (bpm * (bpm2x - 195) * 0.0010),
                                left: 1,
                                right: 1,
                                child: Image.asset(
                                  AppAssets.slider,
                                  height: kIsWeb
                                      ? 37
                                      : isTablet
                                          ? 58
                                          : 37,
                                  width: kIsWeb
                                      ? 37
                                      : isTablet
                                          ? 47
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
                ? 88.0.h
                : isTablet
                    ? 290.0.h
                    : 88.0.h,
            left: 2,
            child: Container(
              height: 260.0,
              width: metroWidth,
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                AppAssets.metronomeBottom,
                height: metroHeight,
                width: kIsWeb
                    ? 203
                    : isTablet
                        ? 410
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
                    value: provider.bpm,
                    min: 40,
                    max: 300,
                    //300,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ButtonsSection extends StatelessWidget {
  const ButtonsSection({
    super.key,
    required this.isTablet,
    required this.provider,
    required this.onButtonTap,
  });

  final MetroProvider provider;
  final bool isTablet;
  final void Function(int) onButtonTap;

  @override
  Widget build(BuildContext context) {
    final height = Utils.height(context);
    return Container(
      height: isTablet
          ? height * 0.6
          : JHGResponsive.isTablet(context)
              ? height * 0.42
              : height * 0.41,
      width: isTablet ? height * 0.1 : height * 0.08,
      child: Theme(
        data: Theme.of(context).copyWith(
          scrollbarTheme: ScrollbarThemeData(
            thumbColor: MaterialStateProperty.all(Colors.transparent),
          ),
        ),
        child: ListView.builder(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            primary: true,
            itemCount: provider.tapButtonList.length + 1,
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            itemBuilder: (context, index) {
              return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      onButtonTap(index);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: height * 0.009),
                      child: Container(
                        height: isTablet ? height * 0.1 : height * 0.08,
                        width: isTablet ? height * 0.1 : height * 0.08,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: provider.selectedButton == index
                              ? AppColors.greySecondary
                              : AppColors.greyPrimary,
                        ),
                        child: Column(
                          mainAxisAlignment: (index == 4)
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            (index == 4)
                                ? Theme(
                                    data: ThemeData(
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                    ),
                                    child: JHGIconButton(
                                      size: kIsWeb
                                          ? 17
                                          : JHGResponsive.isTablet(context)
                                              ? 25
                                              : 20,
                                      iconData: LucideIcons.pen,
                                      isBackGround: false
                                    ),
                                  )
                                    .paddingOnly(
                                        top: 8,
                                        right: kIsWeb ? 0 : 8,
                                        bottom: 0)
                                    .align(Alignment.center)
                                : SizedBox(),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  (index == provider.tapButtonList.length &&
                                          provider.customBeatValue == null)
                                      ? "Custom"
                                      : (index ==
                                                  provider.tapButtonList.length &&
                                              provider.customBeatValue != null)
                                          ? provider.customBeatValue!
                                          : provider.tapButtonList[index],
                                  style: JHGTextStyles.subLabelStyle.copyWith(
                                    color: AppColors.whitePrimary,
                                    fontSize: (index ==
                                                provider.tapButtonList.length &&
                                            provider.customBeatValue == null)
                                        ? 12
                                        : 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ));
            }),
      ),
    );
  }
}