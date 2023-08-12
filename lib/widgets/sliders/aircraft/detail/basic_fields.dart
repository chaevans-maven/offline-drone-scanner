import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_opendroneid/models/message_pack.dart';

import '../../../../bloc/proximity_alerts_cubit.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/sizes.dart';
import '../../../../utils/uasid_prefix_reader.dart';
import '../../../../utils/utils.dart';
import '../../../app/dialogs.dart';
import '../../common/headline.dart';
import 'aircraft_detail_field.dart';
import 'aircraft_detail_row.dart';
import 'aircraft_label_text.dart';

class BasicFields {
  static List<Widget> buildBasicFields(
    BuildContext context,
    List<MessagePack> messagePackList,
  ) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final idTypeString = messagePackList.last.basicIdMessage?.idType.toString();
    final uaTypeString = messagePackList.last.basicIdMessage?.uaType.toString();
    String? manufacturer;
    Image? logo;
    if (messagePackList.isNotEmpty &&
        messagePackList.last.basicIdMessage != null) {
      manufacturer = UASIDPrefixReader.getManufacturerFromUASID(
          messagePackList.last.basicIdMessage!.uasId);
      logo = getManufacturerLogo(
          manufacturer: manufacturer, color: AppColors.lightGray);
    }
    final idTypeLabel =
        idTypeString?.replaceAll('IdType.', '').replaceAll('_', ' ');
    final uaTypeLabel =
        uaTypeString?.replaceAll('UaType.', '').replaceAll('_', ' ');
    final uasId = messagePackList.last.basicIdMessage?.uasId;
    final proximityAlertsActive =
        context.watch<ProximityAlertsCubit>().state.isAlertActiveForId(uasId);
    var colorAccessibleVersion = true;

    return [
      const Headline(text: 'AIRCRAFT'),
      if (isLandscape) const SizedBox(),
      AircraftDetailRow(
        children: [
          AircraftDetailField(
            headlineText: 'UA ID Type',
            fieldText: idTypeLabel,
          ),
          AircraftDetailField(
            headlineText: 'UA Type',
            fieldText: uaTypeLabel,
          ),
        ],
      ),
      AircraftDetailRow(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AircraftDetailField(
                headlineText: 'UAS ID',
                child: logo != null && manufacturer != null
                    ? Text.rich(
                        TextSpan(
                          text: messagePackList.last.basicIdMessage == null
                              ? 'Unknown'
                              : '${messagePackList.last.basicIdMessage?.uasId}',
                          style: const TextStyle(
                            color: AppColors.lightGray,
                          ),
                          children: [
                            TextSpan(text: '\n'),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: logo,
                            ),
                            TextSpan(
                              text: manufacturer,
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
              ElevatedButton(
                onPressed: () {
                  final alertsCubit = context.read<ProximityAlertsCubit>();
                  if (uasId != null &&
                      alertsCubit.state.usersAircraftUASID == uasId) {
                    alertsCubit.clearUsersAircraftUASID();
                    showSnackBar(context, 'Owned aircaft was unset');
                  } else {
                    if (uasId == null) {
                      showSnackBar(context,
                          'Cannot set aircraft as owned: Unknown UAS ID');
                      return;
                    }
                    final validationError = validateUASID(uasId);
                    if (validationError != null) {
                      showSnackBar(
                          context, 'Error parsing UAS ID: $validationError');
                      FocusManager.instance.primaryFocus?.unfocus();
                      return;
                    }
                    alertsCubit.setUsersAircraftUASID(uasId);
                    showSnackBar(context, 'Aircaft set as owned');
                  }
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    proximityAlertsActive ? AppColors.green : Colors.white,
                  ),
                  side: MaterialStateProperty.all<BorderSide>(
                    BorderSide(
                        width: 2.0,
                        color: proximityAlertsActive
                            ? Colors.white
                            : AppColors.green),
                  ),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        right: proximityAlertsActive ? 0 : Sizes.iconPadding,
                      ),
                      child: Icon(
                        Icons.person,
                        size: Sizes.iconSize,
                        color: proximityAlertsActive
                            ? Colors.white
                            : AppColors.green,
                      ),
                    ),
                    if (proximityAlertsActive)
                      Padding(
                        padding:
                            const EdgeInsets.only(right: Sizes.iconPadding),
                        child: Icon(
                          Icons.done,
                          color: Colors.white,
                          size: Sizes.iconSize * 0.75,
                        ),
                      ),
                    Text(
                      proximityAlertsActive ? 'MINE' : 'SET AS MINE',
                      style: TextStyle(
                          fontSize: 12,
                          color: proximityAlertsActive
                              ? Colors.white
                              : AppColors.green),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      AircraftDetailRow(
        children: [
          AircraftLabelText(
            aircraftMac: messagePackList.last.macAddress,
          ),
        ],
      ),
      if (messagePackList.last.selfIdMessage != null &&
          messagePackList.last.selfIdMessage?.operationDescription != null)
        AircraftDetailField(
          headlineText: 'Light Pattern',
          //fieldText: messagePackList.last.selfIdMessage!.operationDescription,
          child: Row(children: [
            ElevatedButton(
                onPressed: () {
                  colorAccessibleVersion = !colorAccessibleVersion;
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    proximityAlertsActive ? AppColors.green : Colors.white,
                  ),
                  side: MaterialStateProperty.all<BorderSide>(
                    BorderSide(
                        width: 2.0,
                        color: proximityAlertsActive
                            ? Colors.white
                            : AppColors.green),
                  ),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        right: proximityAlertsActive ? 0 : Sizes.iconPadding,
                      ),
                      child: Icon(
                        Icons.person,
                        size: Sizes.iconSize,
                        color: proximityAlertsActive
                            ? Colors.white
                            : AppColors.green,
                      ),
                    ),
                    if (proximityAlertsActive)
                      Padding(
                        padding:
                            const EdgeInsets.only(right: Sizes.iconPadding),
                        child: Icon(
                          Icons.done,
                          color: Colors.white,
                          size: Sizes.iconSize * 0.75,
                        ),
                      ),
                    Text(
                      colorAccessibleVersion ? 'Colors on' : 'Colors off',
                      style: TextStyle(
                          fontSize: 12,
                          color: proximityAlertsActive
                              ? Colors.white
                              : AppColors.green),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Container(color: Colors.grey,
              child: colorAccessibleVersion ? 
                blinkingLightPattern(messagePackList.last.selfIdMessage!.operationDescription) : 
                colorLightPattern(messagePackList.last.selfIdMessage!.operationDescription),
              )
          ],)
        ),

        //Container(color: Color.fromRGBO(255, 0, 0, 1.0)),
      if (isLandscape) const SizedBox(),
    ];
  }

  static Color interpretRGBValues(String rgb) {
    var r = rgb.codeUnitAt(0).toDouble();
    var g = rgb.codeUnitAt(1).toDouble();
    var b = rgb.codeUnitAt(2).toDouble();


    var max = r;
    if (g > max) {
      max = g;
    }
    if (b > max) {
      max = b;
    }

    r = r / max * 254;
    g = g / max * 254;
    b = b / max * 254;

    return Color.fromRGBO(r.round(), g.round(), b.round(), 1.0);
  }

  static Row colorLightPattern(String selfId) {
    return Row(
      children: [
        Icon(
          Icons.lightbulb,
          color: interpretRGBValues(selfId.substring(10,13)),
          size: Sizes.iconSize * 2,
        ),
        Icon(
          Icons.lightbulb,
          color: interpretRGBValues(selfId.substring(13,16)),
          size: Sizes.iconSize * 2,
        ),
        Icon(
          Icons.lightbulb,
          color: interpretRGBValues(selfId.substring(16,19)),
          size: Sizes.iconSize * 2,
        ),  
      ],
    );
  }

  static Row blinkingLightPattern(String selfId) {
    var pattern = selfId.codeUnitAt(20);
    List<Widget> patternBinaryList = [];
    for (int i = 7; i >= 0; i--) {
        patternBinaryList.add(Icon(
          Icons.lightbulb,
          color: ((pattern >> i) % 2) == 1 ? Colors.white : Colors.black,
          size: Sizes.iconSize,
        ));
    }
    return Row(
      children: patternBinaryList,
    );
  }
}
