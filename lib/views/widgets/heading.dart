import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:rhythm_master/utils/app_colors.dart';

// ignore: must_be_immutable
class Heading extends StatefulWidget {
  Heading(
      {super.key,
      required this.title,
      required this.numbers,
      this.textColor,
      this.fontSize,
      this.padding,
      this.fontWeight,
      this.addButton,
      this.minusButton,
      this.showButtons = false});

  final String title;
  final String numbers;
  final double? fontSize;
  final Color? textColor;
  final double? padding;
  final FontWeight? fontWeight;
  void Function()? addButton;
  void Function()? minusButton;
  bool showButtons;

  @override
  State<Heading> createState() => _HeadingState();
}

class _HeadingState extends State<Heading> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.padding ?? 14), //width * 0.03),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.title,
            style: JHGTextStyles.labelStyle,
            // JHGTextStyles.lrlabelStyle.copyWith(
            //   color: textColor ?? AppColors.whitePrimary,
            //   fontSize: fontSize ?? 18,
            //   fontWeight: fontWeight ?? FontWeight.w700,
            // ),
          ),
          Row(
            children: [
              Visibility(
                visible: widget.showButtons,
                child: Padding(
                  padding: const EdgeInsets.only(right: 2.0),
                  child: GestureDetector(
                    onLongPressStart: (details) => startIncrementing(widget.minusButton!),
                    onLongPressEnd: (details) => _timer.cancel(),
                    onTap: widget.minusButton,
                    child: Icon(
                      Icons.remove,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(
                width: 38,
                child: Center(
                  child: Text(
                    widget.numbers,
                    style: JHGTextStyles.labelStyle
                        .copyWith(color: AppColors.whitePrimary, fontSize: 24),
                  ),
                ),
              ),
              Visibility(
                visible: widget.showButtons,
                child: Padding(
                  padding: const EdgeInsets.only(left: 2.0),
                  child: GestureDetector(
                    onLongPressStart: (details) => startIncrementing(widget.addButton!),
                    onLongPressEnd: (details) => _timer.cancel(),
                    onTap: widget.addButton,
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  late Timer _timer;

  void startIncrementing(void Function() function) {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      function();
    });
  }
}
