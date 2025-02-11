import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/aircraft/aircraft_cubit.dart';
import '../../../bloc/proximity_alerts_cubit.dart';
import '../../../constants/colors.dart';
import '../../../constants/sizes.dart';

class ProximityAlertWidget extends StatelessWidget {
  final DroneNearbyAlert alert;

  const ProximityAlertWidget({Key? key, required this.alert}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final aircraftCubit = context.read<AircraftCubit>();
    final droneMac = aircraftCubit.findByUasID(alert.uasId)?.macAddress;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.pink),
        borderRadius: BorderRadius.circular(Sizes.panelBorderRadius),
      ),
      padding: EdgeInsets.all(
        Sizes.mapContentMargin / 2,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: Sizes.iconPadding),
                child: Icon(
                  Icons.location_searching,
                  size: Sizes.textIconSize,
                ),
              ),
              // show label if exists
              Text(
                aircraftCubit.state.aircraftLabels.containsKey(droneMac)
                    ? aircraftCubit.state.aircraftLabels[droneMac]!
                    : alert.uasId,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              Spacer(),
              Text(
                '~${alert.distance.toStringAsFixed(1)}m away',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
