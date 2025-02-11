import 'package:another_flushbar/flushbar.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import 'proximity_alert_snackbar.dart';

void showAlertDialog(
  BuildContext context,
  String alertText,
  VoidCallback confirmCallback,
) {
  // set up the buttons
  final Widget cancelButton = TextButton(
    child: const Text('Cancel'),
    onPressed: () {
      Navigator.of(context).pop();
    },
  );
  final Widget continueButton = TextButton(
    child: const Text('Continue'),
    onPressed: () {
      Navigator.of(context).pop();
      confirmCallback();
    },
  );
  // set up the AlertDialog
  final alert = AlertDialog(
    title: const Text('Confirm Deletion'),
    content: Text(alertText),
    actions: [
      cancelButton,
      continueButton,
    ],
  );
  // show the dialog
  showDialog(
    context: context,
    builder: (context) {
      return alert;
    },
  );
}

Future<bool> showLocationPermissionDialog({
  required BuildContext context,
  required bool showWhileUsingPermissionExplanation,
}) async {
  // set up the buttons
  final Widget cancelButton = TextButton(
    child: const Text('Cancel'),
    onPressed: () {
      Navigator.pop(context, false);
    },
  );
  final Widget appSettingsButton = TextButton(
    child: const Text('App settings'),
    onPressed: () {
      Navigator.pop(context, false);
      AppSettings.openAppSettings();
    },
  );
  final Widget continueButton = TextButton(
    child: const Text('Continue'),
    onPressed: () {
      Navigator.pop(context, true);
    },
  );
  // set up the AlertDialog
  final alert = AlertDialog(
    title: const Text('Location permission required'),
    content: Text.rich(
      TextSpan(
        text: 'Drone Scanner requires a location permission to scan for '
            'Bluetooth devices.\n\n',
        children: [
          if (showWhileUsingPermissionExplanation) ...[
            TextSpan(text: 'Please choose\nthe '),
            TextSpan(
              text: '\"While using the app\"\n',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: 'option to enable scans in the background.\n\n',
            ),
          ],
          TextSpan(
              text: 'If you already denied the permission request,'
                  ' please go to\nthe '),
          TextSpan(
            text: '\"App settings\"\n',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: 'and enable location manually.'),
        ],
      ),
    ),
    actions: [
      cancelButton,
      appSettingsButton,
      continueButton,
    ],
  );
  // show the dialog
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return alert;
    },
  );
  return result ?? false;
}

void showSnackBar(
  BuildContext context,
  String snackBarText, {
  Color textColor = Colors.white,
  int durationMs = 1500,
}) {
  final snackBar = SnackBar(
    backgroundColor: AppColors.darkGray.withOpacity(AppColors.toolbarOpacity),
    duration: Duration(milliseconds: durationMs),
    behavior: SnackBarBehavior.floating,
    content: Text(
      snackBarText,
      style: TextStyle(color: textColor),
    ),
    margin: EdgeInsets.only(
      bottom: MediaQuery.of(context).size.height / 10,
      right: Sizes.mapContentMargin,
      left: Sizes.mapContentMargin,
    ),
  );
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

Flushbar createProximityAlertFlushBar(BuildContext context, int durationSec) {
  return Flushbar(
    duration: Duration(seconds: durationSec),
    backgroundColor: Colors.transparent,
    flushbarPosition: FlushbarPosition.TOP,
    padding: EdgeInsets.symmetric(
      horizontal: Sizes.mapContentMargin,
      vertical: Sizes.standard,
    ),
    messageText: ProximityAlertSnackbar(
      expirationTime: durationSec,
    ),
  );
}
