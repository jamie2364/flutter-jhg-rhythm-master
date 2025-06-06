import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:rhythm_master/utils/app_strings.dart';
import 'package:rhythm_master/views/extension/int_extension.dart';
import 'package:rhythm_master/views/extension/widget_extension.dart';

class AppUtils {
  // percent values range between 1-0
  static double getWidth(BuildContext context, {double percent = 1}) {
    return (MediaQuery.of(context).size.width) * percent;
  }

  // percent values range between 1-0
  static double getHeight(BuildContext context, {double percent = 1}) {
    return (MediaQuery.of(context).size.height) * percent;
  }

  static EdgeInsets getWebDropdownEdgeInsets() {
    return EdgeInsets.symmetric(vertical: 12, horizontal: 15);
  }

  static bool isWeb() {
    return kIsWeb;
  }

  AppUtils._();
  static void showPopup(
    BuildContext context,
    String chordName,
    String details,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: ThemeData(
            useMaterial3: false,
            dialogTheme:
                DialogThemeData(backgroundColor: JHGColors.charcolGray),
            // Set the text color
          ),
          child: Dialog(
            insetPadding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            backgroundColor: JHGColors.charcolGray,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  20.0), // Set circular border radius for content
            ),
            child: Container(
                width: 360.0.w,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    JHGIconButton(
                      size: 40.0.w,
                      iconData: Icons.close,
                      onTap: () => Navigator.pop(context),
                    ).align(Alignment.topRight),
                    10.0.height,
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(chordName,
                            style: JHGTextStyles.lrlabelStyle
                                .copyWith(fontSize: 21)),
                        25.0.height,
                        Text(
                          details,
                          style: JHGTextStyles.bodyStyle.copyWith(
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                        80.0.height,
                        JHGButton(
                          label: AppStrings.done,
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        )
                      ],
                    ).paddingAll(20.0.w)
                  ],
                ).paddingAll(20.0.w)),
          ),
        );
      },
    );
  }

  static File setWebAsset(soundTracks) {
    Uri uri =
        Uri.parse("${kDebugMode ? '${AppStrings.webAsset}/' : ''}$soundTracks");
    File file = File.fromUri(uri);
    // print('file path:::-------------- ${file.path}');
    return file;
  }
}
