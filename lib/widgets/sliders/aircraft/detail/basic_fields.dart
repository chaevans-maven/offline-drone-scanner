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
          //fieldText: (int.parse(messagePackList.last.selfIdMessage!.operationDescription.substring(6, 9)) - 100).toString(),
          child: Container(
            color: Colors.black,
            child: Row(children: [
                Icon(
                  Icons.lightbulb,
                  color: Color.fromRGBO(
                  (int.parse(messagePackList.last.selfIdMessage!.operationDescription.substring(3, 6)) - 100) * 25,
                  (int.parse(messagePackList.last.selfIdMessage!.operationDescription.substring(0, 3)) - 100) * 25,
                  (int.parse(messagePackList.last.selfIdMessage!.operationDescription.substring(6, 9)) - 100) * 25,
                  1.0),
                  size: Sizes.iconSize * 2,
                ),
                Icon(
                  Icons.lightbulb,
                  color: Color.fromRGBO(
                  (int.parse(messagePackList.last.selfIdMessage!.operationDescription.substring(12, 15)) - 100) * 25,
                  (int.parse(messagePackList.last.selfIdMessage!.operationDescription.substring(9, 12)) - 100) * 25,
                  (int.parse(messagePackList.last.selfIdMessage!.operationDescription.substring(15, 18)) - 100) * 25,
                  1.0),
                  size: Sizes.iconSize * 2,
                ),
                Icon(
                  Icons.lightbulb,
                  color: Color.fromRGBO(
                  (int.parse(messagePackList.last.selfIdMessage!.operationDescription.substring(21, 24)) - 100) * 25,
                  (int.parse(messagePackList.last.selfIdMessage!.operationDescription.substring(18, 21)) - 100) * 25,
                  (int.parse(messagePackList.last.selfIdMessage!.operationDescription.substring(24, 27)) - 100) * 25,
                  1.0),
                  size: Sizes.iconSize * 2,
                ),
                Icon(
                  Icons.lightbulb,
                  color: Color.fromRGBO(
                  (int.parse(messagePackList.last.selfIdMessage!.operationDescription.substring(30, 33)) - 100) * 25,
                  (int.parse(messagePackList.last.selfIdMessage!.operationDescription.substring(27, 30)) - 100) * 25,
                  (int.parse(messagePackList.last.selfIdMessage!.operationDescription.substring(33, 36)) - 100) * 25,
                  1.0),
                  size: Sizes.iconSize * 2,
                ),
                Icon(
                  Icons.lightbulb,
                  color: Color.fromRGBO(
                  (int.parse(messagePackList.last.selfIdMessage!.operationDescription.substring(39, 42)) - 100) * 25,
                  (int.parse(messagePackList.last.selfIdMessage!.operationDescription.substring(36, 39)) - 100) * 25,
                  (int.parse(messagePackList.last.selfIdMessage!.operationDescription.substring(42, 45)) - 100) * 25,
                  1.0),
                  size: Sizes.iconSize * 2,
                ),            
              ],
            ),
          )
        ),

        //Container(color: Color.fromRGBO(255, 0, 0, 1.0)),
      if (isLandscape) const SizedBox(),
    ];
  }
}
