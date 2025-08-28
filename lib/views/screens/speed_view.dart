import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:provider/provider.dart';
import 'package:rhythm_master/utils/app_strings.dart';
import 'package:rhythm_master/providers/setting_provider.dart';
import 'package:rhythm_master/providers/speed_provider.dart';
import 'package:rhythm_master/views/extension/int_extension.dart';
import 'package:rhythm_master/views/extension/widget_extension.dart';
import 'package:rhythm_master/views/widgets/bpm_value_widget.dart';
import 'package:rhythm_master/views/widgets/custom_slider_widget.dart';
import 'package:rhythm_master/views/widgets/heading.dart';

class SpeedView extends StatefulWidget {
  const SpeedView({super.key});

  @override
  State<SpeedView> createState() => _SpeedViewState();
}

class _SpeedViewState extends State<SpeedView> with TickerProviderStateMixin {
  @override
  void initState() {
    final speedProvider = Provider.of<SpeedProvider>(context, listen: false);
    speedProvider.initializeAnimationController();
    settingProvider = Provider.of<SettingProvider>(context, listen: false);
    super.initState();
  }

  SpeedProvider? speedProvider;
  SettingProvider? settingProvider;

  @override
  void didChangeDependencies() {
    speedProvider = Provider.of<SpeedProvider>(context, listen: false);
    settingProvider = Provider.of<SettingProvider>(context, listen: false);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    speedProvider!.clearSpeedTrainer(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Consumer<SpeedProvider>(builder: (context, controller, child) {
      return Column(
        children: [
          kIsWeb ? 10.0.height : 15.0.height,
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(maxWidth:
                JHGResponsive.isTablet(context)? 720:
                345),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SPACER
                    kIsWeb ? 12.0.height :JHGResponsive.isTablet(context)? 95.0.height:  22.0.height,
                    // STARTING TEMPO
                    Heading(
                      title: AppStrings.startingTempo,
                      numbers: controller.startTempo.toStringAsFixed(0),
                      showButtons: true,
                      addButton: () {controller.incrementTempo(settingProvider!.speedDefaultInterval.toInt());
                      },
                      minusButton: () {
                        controller.decrementTempo(
                            settingProvider!.speedDefaultInterval.toInt());
                      },
                    ),
                    // SPACER
                    kIsWeb ? 6.0.height :

                    JHGResponsive.isTablet(context)? 16.0.height:
                    12.0.height,
                    // STARTING SLIDER
                    SliderWidget(
                        height: height,
                        min: controller.startTempoMin,
                        max: controller.startTempoMax,
                        value: controller.startTempo,
                        onChanged: (values) {
                          controller.setStartTempo(values);
                        }),
                    // SPACER
                    kIsWeb ? 12.0.height :
                    JHGResponsive.isTablet(context)? 26.0.height:
                    18.0.height,
                    // TARGET TEMPO
                    Heading(
                      title: AppStrings.targetTempo,
                      numbers: controller.targetTempo.toStringAsFixed(0),
                      showButtons: true,
                      addButton: () {
                        controller.incrementTargetTempo(
                            settingProvider!.speedDefaultInterval.toInt());
                      },
                      minusButton: () {
                        controller.decrementTargetTempo(
                            settingProvider!.speedDefaultInterval.toInt());
                      },
                    ),
                    // SPACER
                    kIsWeb ? 12.0.height :

                    JHGResponsive.isTablet(context)? 28.0.height:
                    22.0.height,
                    // TARGET SLIDER
                    SliderWidget(
                      height: height,
                      min: controller.targetTempoMin,
                      max: controller.targetTempoMax,
                      value: controller.targetTempo,
                      onChanged: (values) {
                        controller.setTargetTempo(values);
                      },
                    ),

                    // SPACER
                    kIsWeb ? 8.0.height :

                    JHGResponsive.isTablet(context)? 18.0.height:
                    12.0.height,
                    // BARS
                    JHGHeadAndSubHWidget(
                      AppStrings.bars,
                      lableStyle:
                          JHGTextStyles.headLabelStyle.copyWith(fontSize: 18),
                      subLableStyle:
                          JHGTextStyles.subLabelStyle.copyWith(fontSize: 12),
                      subLabel: AppStrings.howManyBars,
                      margin: EdgeInsets.only(
                        top: JHGHeadAndSubHWidget.top,
                        bottom: JHGHeadAndSubHWidget.bottom,
                        left: 10,
                        right: 10,
                      ),
                      actions: [
                        JHGValueIncDec(
                          initialValue: controller.bar,
                          onChanged: (int newValue) {
                            controller.onChangedBar(newValue);
                          },
                          maxValue: 60,
                        ),
                      ],
                    ).paddingSymmetric(
                      horizontal:           JHGResponsive.isTablet(context)? 5:0,
                    ),
                    JHGResponsive.isTablet(context)? 5.0.height:0.0.height,

                    JHGHeadAndSubHWidget(
                      AppStrings.interval,
                      margin: EdgeInsets.only(
                        top: JHGHeadAndSubHWidget.top,
                        bottom: JHGHeadAndSubHWidget.bottom,
                        left: 10,
                        right: 10,
                      ),
                      subLabel:
                          "${AppStrings.howMuchItShouldIncrease} ${controller.bar} Bars",
                      lableStyle:
                          JHGTextStyles.headLabelStyle.copyWith(fontSize: 18),
                      subLableStyle:
                          JHGTextStyles.subLabelStyle.copyWith(fontSize: 12),
                      actions: [
                        JHGValueIncDec(
                          initialValue: controller.interval,
                          //interval: controller.gafInterval.toInt(),
                          onChanged: (int newValue) =>
                              controller.onChangedInterval(newValue),
                          maxValue: 120,
                        ),
                      ],
                    ).paddingSymmetric(
                      horizontal:           JHGResponsive.isTablet(context)? 5:0,
                    ),
                    // INTERVAL BUTTONS
                    // SPACER
                    kIsWeb
                        ? 14.0.height
                        :
                        // BARS
                        25.0.height,
                    // BPM VALUE SECTION
                    // Reset and play pause BUTTON
                  ],
                ),
              ),
            ),
          ),
          kIsWeb ? 30.0.height : 0.0.height,
          // Text(
          //     'BPM IS ${controller.bpm} targetTempo is ${controller.targetTempo}'),
          BpmValueWidget(
            bpmValue: controller.bpm > controller.targetTempo
                ? controller.targetTempo.toStringAsFixed(0)
                : controller.bpm.toStringAsFixed(0),
          ).center,
          JHGAppBar(
            isResponsive: true,
            isBottom: true,
            crossAxisAlignment: CrossAxisAlignment.end,
            leadingWidget: JHGResetBtn(
                enabled: true,
                onTap: () {
                  controller.clearSpeedTrainer(true);
                }),
            centerWidget: JHGPlayPauseBtn(
                isPlaying: controller.isPlaying,
                onChanged: (val) {
                  controller.startStop();
                }),
          ),
        ],
      );
    });
  }
}
