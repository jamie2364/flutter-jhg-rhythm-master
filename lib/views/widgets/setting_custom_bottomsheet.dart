import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:provider/provider.dart';
import 'package:rhythm_master/utils/app_colors.dart';
import 'package:rhythm_master/utils/app_strings.dart';
import 'package:rhythm_master/providers/setting_provider.dart';
import 'package:rhythm_master/views/extension/widget_extension.dart';
import 'bottom_sheet_widget.dart';

settingCustomBottomSheet(BuildContext context,bool isMetronome){
  return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:  AppColors.greyPrimary,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          )
      ),
      builder: (context){
       final height =  MediaQuery.sizeOf(context).height;
       final  width =  MediaQuery.sizeOf(context).width;
        return  Consumer<SettingProvider>(
          builder: (context,controller,child) {
            return Stack(
              children: [
                Container(
                  height:  height*0.85,
                  width: width,
                  decoration: BoxDecoration(
                      color: AppColors.greyPrimary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    )
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 17,),
                        Center(
                          child: Container(
                            height: 5,
                            width: 60,
                            decoration: BoxDecoration(
                                color: AppColors.whiteTextColor,
                              borderRadius: BorderRadius.circular(100)
                            ),
                          ),
                        ),
                        SizedBox(height: 40),
                        BottomSheetWidget(
                            title:  "Number of Beats",
                            subtitle:   "This is the top number and represents how many sounds you will hear between each accented note.",
                            numbers:  controller.beatNumerator.toString(),
                            onAdd: () {
                              controller.incrementBeatNumerator();
                            },
                            onSubtract: () {
                              controller.decrementBeatNumerator();
                            }
                        ),
                        SizedBox(height: 30),
                        BottomSheetWidget(
                            title:   "Note Value",
                            subtitle:   "This is the bottom number and represents, in combination with the BPM setting how quickly the sounds will play.",
                            numbers:  controller.beatDenominator.toString(),
                            onAdd: () {
                              controller.incrementBeatDenominator();
                            },
                            onSubtract: () {
                              controller.decrementBeatDenominator();
                            }
                        ),
                        SizedBox(height: 30),
                        Center(
                          child: Text(
                            "Time Signature",
                            style: JHGTextStyles.lrlabelStyle.copyWith(fontSize: 18),
                          ),
                        ),
                        SizedBox(height: 20),
                        Center(
                          child:
                        Text("${controller.beatNumerator}/${controller.beatDenominator}",
                          style: JHGTextStyles.lrlabelStyle.copyWith(fontSize: 40),
                        ),),
                        SizedBox(height: 35),

                           InkWell(
                             onTap: () async {
                               Navigator.pop(context);
                               if(isMetronome == true){
                                 controller.setValueOfMetronomeBottomSheet();
                               }else{
                                 controller.setValueOfSpeedTrainerBottomSheet();
                               }
                             },
                             child: Center(
                               child: Container(
                                 height: height * 0.07,
                                 width: width * 1,
                                 alignment: Alignment.center,
                                 decoration: BoxDecoration(
                                     color: AppColors.redPrimary,
                                     borderRadius: BorderRadius.circular(10)),
                                 child: Text(
                                   AppStrings.save,
                                   style:  JHGTextStyles.labelStyle.copyWith(fontSize: 17),
                                 ),
                               ),
                             ),
                           ),
                        SizedBox(height: 25),
                        JHGResetBtn(
                                enabled: true,
                                onTap: () {
                                  controller.resetSettingCustomBottomSheet();
                                }).center,

                      ],
                    ),
                  ),
                ),
                // Positioned(
                //     bottom: 80,
                //     right: 180,
                //     child:
                //     Align(
                //       alignment: Alignment.centerRight,
                //       child: JHGResetBtn(
                //           enabled: true,
                //           onTap: () {
                //             //controller.clearMetronome();
                //           }),
                //     ))
              ],
            );
          }
        );
      });
}