import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:rhythm_master/utils/app_colors.dart';

class BeatsNumberButton extends StatefulWidget {
  const BeatsNumberButton({
    super.key,
    required this.numbers,
    required this.onAdd,
    required this.onSubtract,
  });

  final String numbers;
  final VoidCallback onSubtract;
  final VoidCallback onAdd;

  @override
  State<BeatsNumberButton> createState() => _BeatsNumberButtonState();
}

class _BeatsNumberButtonState extends State<BeatsNumberButton> {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final width = MediaQuery.sizeOf(context).width;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // MINUS BUTTON
        MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onLongPressStart: (details) => startIncrementing(widget.onSubtract),
              onLongPressEnd: (details) => _timer.cancel(),
              onTap: (widget.onSubtract),
              child: Container(
                height: height * 0.038,
                width: height * 0.038,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: AppColors.redPrimary,
                ),
                child: Center(
                    child: Icon(
                  LucideIcons.minus300,
                  color: AppColors.whitePrimary,
                )),
              ),
            )),

        SizedBox(width: 25),

        Container(
          height: height * 0.065,
          width: width * 0.18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: AppColors.greyPrimary,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.numbers,
            style: JHGTextStyles.subLabelStyle.copyWith(
              fontSize: 32,
            ),
          ),
        ),

        SizedBox(width: 25),
        // PLUS BUTTON

        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(  onLongPressStart: (details) => startIncrementing(widget.onAdd),
            onLongPressEnd: (details) => _timer.cancel(),
            onTap: (widget.onAdd),
            child: Container(
              height: height * 0.038,
              width: height * 0.038,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: AppColors.redPrimary,
              ),
              child: Center(
                  child: Icon(
                LucideIcons.plus300,
                color: AppColors.whitePrimary,
              )),
            ),
          ),
        )
      ],
    );
  }

  late Timer _timer;

  void startIncrementing(void Function() function) {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      function();
    });
  }
}
