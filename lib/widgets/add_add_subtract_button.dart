import 'package:flutter/material.dart';
import '../utils/app_ colors.dart';
import '../utils/app_constant.dart';

class AddAndSubtractButton extends StatelessWidget {
  const AddAndSubtractButton({super.key,
    required this.title,
    required this.numbers,
    required this.description,
    required this.onAdd,
    required this.onSubtract,
    this.redButtonSize,
    this.greyButtonSize,
    this.headingSize,
    this.padding,
  });

  final String  title;
  final String  description;
  final String  numbers;
  final VoidCallback onSubtract;
  final VoidCallback onAdd;
  final double? redButtonSize;
  final double? greyButtonSize;
  final double? headingSize;
  final double? padding;



  @override
  Widget build(BuildContext context) {


    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return   Padding(
      padding: EdgeInsets.symmetric(horizontal:padding?? width*0.03),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: height*0.07,
            width: width,

            child: Row(

              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //how many bars

                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppConstant.sansFont,
                    color: AppColors.whiteLight,
                    fontSize: headingSize ?? 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),


                Row(

                  children: [

                    // MINUS BUTTON
                    GestureDetector(
                      onTap: (onSubtract),
                      child: Container(
                        height: redButtonSize ?? height * 0.038,
                        width:redButtonSize ?? height * 0.038,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color:  AppColors.redPrimary,
                        ),
                        child: Center(
                            child:
                            Icon(Icons.remove,color: AppColors.whitePrimary,)
                        ),
                      ),
                    ),

                    SizedBox(width: width * 0.05),



                    Container(
                      height: height * 0.065,
                      width: greyButtonSize ?? width * 0.18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color:  AppColors.greyPrimary,
                      ),
                      child: Center(
                        child:
                        Text(
                          numbers,
                          style: TextStyle(
                            fontFamily: AppConstant.sansFont,
                            color: AppColors.whitePrimary,
                            fontSize: 25,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),


                    SizedBox(width: width * 0.05),
                    // PLUS BUTTON

                    GestureDetector(
                      onTap: (onAdd),
                      child: Container(
                        height:redButtonSize ?? height * 0.038,
                        width: redButtonSize ??height * 0.038,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color:  AppColors.redPrimary,
                        ),
                        child: Center(
                            child:
                            Icon(Icons.add,color: AppColors.whitePrimary,)
                        ),
                      ),
                    ),

                  ],)

              ],
            ),
          ),

          SizedBox(height: height*0.01,),

          Text(
            description,
            style: TextStyle(
              fontFamily: AppConstant.sansFont,
              color: AppColors.whiteLight,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}