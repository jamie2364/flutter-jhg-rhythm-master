import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:provider/provider.dart';
import 'package:rhythm_master/utils/app_colors.dart';
import 'package:rhythm_master/utils/app_strings.dart';
import 'package:rhythm_master/providers/tap_temp_provider.dart';
import 'package:rhythm_master/views/widgets/bpm_value_widget.dart';

class BpmView extends StatefulWidget {
  const BpmView({super.key});

  @override
  State<BpmView> createState() => _BpmViewState();
}


class _BpmViewState extends State<BpmView> {

  @override
  void initState() {
    clearBpm();
    super.initState();
  }
  clearBpm(){
    Future.delayed(Duration.zero,(){
      final controller = Provider.of<TapTempoProvider>(context,listen: false);
      controller.clearBPM();
    });

  }
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Consumer<TapTempoProvider>(builder: (context, controller, child) {
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(maxWidth: 345),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // SPACER
                    SizedBox(height:JHGResponsive.isTablet(context)? height*0.15: height * 0.07),

                    // THIS SONG IS ANDANTE SECTION
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.thisSongIs,
                          style: JHGTextStyles.lrlabelStyle.copyWith(
                            color: AppColors.whiteLight,
                            fontSize: JHGResponsive.isTablet(context)? 20:16,
                          ),
                        ),
                        Text(
                          controller.musicName,
                          style: JHGTextStyles.lrlabelStyle.copyWith(
                            color: AppColors.whiteLight,
                            fontSize:JHGResponsive.isTablet(context)? 28: 24,
                          ),
                        ),
                      ],
                    ),

                    // SPACER
                    SizedBox(height:JHGResponsive.isTablet(context)? height*0.08: height * 0.06,),

                    // RED  TAP BUTTON
                    JHGIconButton(
                      onTap: () {
                        controller.handleTap();
                      },
                      child: AnimatedScale(
                        curve: Curves.easeIn,
                        duration: const Duration(milliseconds: 100),
                        scale: controller.buttonScale,
                        child: Container(
                          height: JHGResponsive.isTablet(context)? height*0.18: height * 0.16,
                          width: JHGResponsive.isTablet(context)? height*0.18:height * 0.16,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.redPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            AppStrings.tap,
                            style: JHGTextStyles.labelStyle.copyWith(
                              fontSize: JHGResponsive.isTablet(context)? 24: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // SPACER
                    SizedBox(height: JHGResponsive.isTablet(context)? height*0.08:height * 0.07,),

                    JHGResetBtn(
                        enabled: true,
                        onTap: () {
                          controller.clearBPM();
                        }),

                    // SPACER
                    SizedBox(height:JHGResponsive.isTablet(context)? height*0.07: height * 0.06,),

                    // BPM VALUE SECTION
                    BpmValueWidget(bpmValue:controller.bpm == null ? AppStrings.bpmNull : controller.bpm!.toStringAsFixed(0),),

                    SizedBox(height: height * 0.1,),

                  ],
                ),
              ), 
            ),
          ),
        ],
      );
    });
  }
}
