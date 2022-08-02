import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/aircraft/aircraft_cubit.dart';
import '../../../bloc/aircraft/selected_aircraft_cubit.dart';
import '../../../bloc/map/map_cubit.dart';
import '../../../bloc/sliders_cubit.dart';
import '../../../bloc/zones/selected_zone_cubit.dart';
import '../../../constants/sizes.dart';
import '../../app/dialogs.dart';

enum AircraftAction {
  delete,
  share,
  export,
  mapLock,
}

Future<AircraftAction?> displayAircraftActionMenu(BuildContext context) async {
  return showMenu<AircraftAction>(
    context: context,
    items: [
      PopupMenuItem(
        value: AircraftAction.mapLock,
        child: Text(
          context.read<MapCubit>().state.lockOnPoint ? 'Unock Map' : 'Lock Map',
        ),
      ),
      const PopupMenuItem(
        value: AircraftAction.share,
        child: Text('Export Data'),
      ),
      const PopupMenuItem(
        value: AircraftAction.delete,
        child: Text('Delete'),
      ),
    ],
    position: RelativeRect.fromLTRB(
      MediaQuery.of(context).size.width,
      context.read<SlidersCubit>().panelController.isPanelOpen
          ? MediaQuery.of(context).size.height / 6
          : MediaQuery.of(context).size.height / 4 * 3,
      Sizes.screenSpacing,
      Sizes.screenSpacing,
    ),
  );
}

void handleAction(BuildContext context, AircraftAction action) {
  final zoneItem = context.read<SelectedZoneCubit>().state.selectedZone;
  final selectedMac =
      context.read<SelectedAircraftCubit>().state.selectedAircraftMac;
  if (selectedMac == null) return;
  final messagePackList = context.read<AircraftCubit>().packsForDevice(
        selectedMac,
      );
  if (messagePackList == null || messagePackList.isEmpty) {
    return;
  }

  switch (action) {
    case AircraftAction.delete:
      showAlertDialog(
        context,
        'Would you really like to delete aircraft data?',
        () {
          context.read<SlidersCubit>().setShowDroneDetail(show: false);
          context.read<AircraftCubit>().deletePack(selectedMac);
          showSnackBar(
            context,
            'Aircraft data were deleted.',
          );
        },
      );
      break;
    case AircraftAction.share:
      context
          .read<AircraftCubit>()
          .exportPackToCSV(mac: messagePackList.last.macAddress, save: false)
          .then(
        (value) {
          if (value.isNotEmpty) {
            showSnackBar(context, 'CSV shared successfuly.');
          }
        },
      );
      break;
    case AircraftAction.export:
      context
          .read<AircraftCubit>()
          .exportPackToCSV(mac: messagePackList.last.macAddress, save: true)
          .then(
        (value) {
          showSnackBar(context, 'Saved successfuly to $value');
        },
      );
      break;
    case AircraftAction.mapLock:
      late final String snackBarText;
      // if setting lock or centering to zone, hide slider to snap point
      if (!context.read<MapCubit>().state.lockOnPoint) {
        context.read<SlidersCubit>().panelController.animatePanelToSnapPoint();
        snackBarText = 'Map center locked on aircraft.';
      } else {
        snackBarText = 'Map center lock on aircraft was disabled.';
      }
      // aircraft
      if (messagePackList.isNotEmpty &&
          messagePackList.last.locationMessage != null &&
          messagePackList.last.locationMessage!.longitude != null &&
          messagePackList.last.locationMessage!.latitude != null) {
        context.read<MapCubit>().toggleLockOnPoint();
        context.read<MapCubit>().centerToLocDouble(
              messagePackList.last.locationMessage!.latitude!,
              messagePackList.last.locationMessage!.longitude!,
            );
      } else {
        if (zoneItem != null) {
          context.read<MapCubit>().centerToLocDouble(
                zoneItem.coordinates.first.latitude,
                zoneItem.coordinates.first.longitude,
              );
        }
      }
      showSnackBar(context, snackBarText);
      break;
    default:
  }
}
