import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:rhythm_master/models/sound_model.dart';
import 'package:rhythm_master/providers/setting_provider.dart';
import 'package:rhythm_master/providers/speed_provider.dart';
import 'package:rhythm_master/utils/app_colors.dart';
import 'package:rhythm_master/utils/app_strings.dart';
import 'package:rhythm_master/views/widgets/heading.dart';
import 'package:rhythm_master/views/widgets/setting_custom_bottomsheet.dart';

class SpeedTrainerSetting extends StatelessWidget {
  const SpeedTrainerSetting(
      {super.key, required this.controller, required this.speedController});

  final SettingProvider controller;
  final SpeedProvider speedController;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return ListView(
      physics: AlwaysScrollableScrollPhysics(),
      children: [
        // SPEED TRAINER HEADING
        Heading(
          padding: 0,
          title: AppStrings.speedTrainer,
          numbers: "",
          fontSize: 22,
          fontWeight: FontWeight.bold,
          textColor: AppColors.headingColor,
        ),
        SizedBox(
          height: height * 0.01,
        ),
        Heading(
          padding: 0,
          title: AppStrings.defaultSound,
          numbers: "",
          fontSize: 14,
          textColor: AppColors.headingColor,
        ),
        // SPACER
        SizedBox(height: height * 0.01),
        Container(
          width: width * 1,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: AppColors.greyPrimary,
          ),
          child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: JHGDropDown(
                value: soundList[controller.speedTrainerSelectedIndex],
                items: soundList,
                onChanged: (values) async {
                  controller.setSpeedTrainerSound(
                    name: values!.name.toString(),
                    beat1: values.beat1.toString(),
                    beat2: values.beat2.toString().toString(),
                    index: values.id!,
                  );
                },
              )),
        ),
        SizedBox(
          height: height * 0.01,
        ),
        // DEFAULT SOUND
        Heading(
          padding: 0,
          title: AppStrings.defaultTiming,
          numbers: "",
          fontSize: 14,
          textColor: AppColors.headingColor,
        ),
        SizedBox(
          height: height * 0.01,
        ),
        // Button selection 3/3 ....
        SizedBox(
          height: height * 0.085,
          width: width * 0.85,
          child: ListView.builder(
              itemCount: controller.tapSpeedTrainerButtonList.length + 1,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () async {
                      if (index ==
                          controller.tapSpeedTrainerButtonList.length) {
                        controller.clearBottomSheetBeats();
                        settingCustomBottomSheet(context, false);
                      } else {
                        controller.setSpeedTrainerBeats(
                            index, controller.tapSpeedTrainerButtonList[index]);
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.only(right: width * 0.025),
                      child: Container(
                        height: height * 0.085,
                        width: height * 0.085,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: controller.selectedSpeedTrainerButton == index
                              ? AppColors.greySecondary
                              : AppColors.greyPrimary,
                        ),
                        child: Center(
                          child: Text(
                            index == controller.tapSpeedTrainerButtonList.length
                                ? "Custom"
                                : controller.tapSpeedTrainerButtonList[index],
                            style: JHGTextStyles.subLabelStyle.copyWith(
                              color: AppColors.whitePrimary,
                              fontSize: index ==
                                      controller
                                          .tapSpeedTrainerButtonList.length
                                  ? 12
                                  : 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
        ),

        SizedBox(
          height: height * 0.02,
        ),

        JHGHeadAndSubHWidget(
          AppStrings.defaultBars,
          margin: EdgeInsets.only(
            bottom: JHGHeadAndSubHWidget.bottom,
            left: 10,
            right: 10,
          ),
          lableStyle: JHGTextStyles.headLabelStyle.copyWith(fontSize: 18),
          actions: [
            JHGValueIncDec(
              initialValue: speedController.defaultBar,
              //interval: controller.gafInterval.toInt(),
              onChanged: (int newValue) =>
                  speedController.onChangedDefaultBar(newValue),
              maxValue: 120,
            ),
          ],
        ),

        JHGHeadAndSubHWidget(
          AppStrings.defaultInterval,
          margin: EdgeInsets.only(
            bottom: JHGHeadAndSubHWidget.bottom,
            left: 10,
            right: 10,
          ),
          lableStyle: JHGTextStyles.headLabelStyle.copyWith(fontSize: 18),
          actions: [
            JHGValueIncDec(
              initialValue: speedController.defaultInterval,
              //interval: controller.gafInterval.toInt(),
              onChanged: (int newValue) =>
                  speedController.onChangedDefaultInterval(newValue),
              maxValue: 120,
            ),
          ],
        ),

        JHGHeadAndSubHWidget(
          AppStrings.sliderInterval,
          margin: EdgeInsets.only(
            left: 10,
            right: 10,
          ),
          lableStyle: JHGTextStyles.headLabelStyle.copyWith(fontSize: 18),
          actions: [
            JHGValueIncDec(
              initialValue: speedController.sliderInterval.toInt(),
              //interval: controller.gafInterval.toInt(),
              onChanged: (int newValue) =>
                  speedController.onChangedSliderInterval(newValue),
              maxValue: 120,
            ),
          ],
        ),
        SizedBox(
          height: height * 0.03,
        ),
      ],
    );
  }
}
