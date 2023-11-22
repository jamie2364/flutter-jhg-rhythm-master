import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm_master/providers/tap_temp_provider.dart';
import 'package:rhythm_master/utils/images.dart';
import '../utils/app_ colors.dart';
import '../utils/app_constant.dart';

class BpmView extends StatelessWidget {
  const BpmView({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Consumer<TapTempoProvider>(builder: (context, controller, child) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // SPACER
          SizedBox(height: height * 0.09),

          // THIS SONG IS ANDANTE SECTION
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppConstant.thisSongIs,
                style: TextStyle(
                  fontFamily: AppConstant.sansFont,
                  color: AppColors.whiteLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                controller.musicName,
                style: TextStyle(
                  fontFamily: AppConstant.sansFont,
                  color: AppColors.whiteLight,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          // SPACER
          SizedBox(
            height: height * 0.104,
          ),

          // RED  TAP BUTTON
          InkWell(
            onTap: () {
              controller.handleTap();
            },
            child: AnimatedScale(
              curve: Curves.easeIn,
              duration: const Duration(milliseconds: 100),
              scale: controller.buttonScale,
              child: Container(
                height: height * 0.16,
                width: height * 0.16,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.redPrimary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  AppConstant.tap,
                  style: TextStyle(
                    fontFamily: AppConstant.sansFont,
                    color: AppColors.whitePrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // SPACER
          SizedBox(
            height: height * 0.10,
          ),

          // RESET BUTTON
          GestureDetector(
            onTap: () {
              controller.clearBPM();
            },
            child: Container(
              height: height * 0.045,
              width: height * 0.045,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                Images.iconReset,
                color: AppColors.whitePrimary,
              ),
            ),
          ),

          // SPACER
          SizedBox(
            height: height * 0.095,
          ),

          // BPM VALUE SECTION
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppConstant.bpm,
                style: TextStyle(
                  fontFamily: AppConstant.sansFont,
                  color: AppColors.whiteSecondary,
                  fontSize: 40,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                controller.bpm == null
                    ? AppConstant.bpmNull
                    : controller.bpm!.toStringAsFixed(0),
                style: TextStyle(
                  fontFamily: AppConstant.sansFont,
                  color: AppColors.whiteSecondary,
                  fontSize: 40,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}
