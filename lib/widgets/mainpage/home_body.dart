import 'dart:async';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock/wakelock.dart';

import '../../bloc/proximity_alerts_cubit.dart';
import '../../bloc/screen_cubit.dart';
import '../../bloc/showcase_cubit.dart';
import '../../constants/sizes.dart';
import '../app/dialogs.dart';
import '../showcase/showcase_item.dart';
import '../sliders/airspace_sliding_panel.dart';
import '../toolbars/map_options_toolbar.dart';
import '../toolbars/toolbar.dart';
import 'map_ui_google.dart';

class HomeBody extends StatefulWidget {
  const HomeBody({
    Key? key,
  }) : super(key: key);

  @override
  _HomeBodyState createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> with WidgetsBindingObserver {
  BuildContext? currentContext;
  StreamSubscription? alertsStreamSub;
  Flushbar? alertFlushbar;
  AppLifecycleState _notification = AppLifecycleState.resumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _notification = state;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    final alertsCubit = context.read<ProximityAlertsCubit>();
    alertsStreamSub = alertsCubit.alertStateStream.listen(
      (event) {
        if (currentContext == null || !currentContext!.mounted) return;
        if (event is AlertStart) {
          showSnackBar(
            currentContext!,
            'Drone Radar is enabled for drone with UAS ID '
            '${alertsCubit.state.usersAircraftUASID}',
            durationMs: 10000,
          );
        } else if (event is AlertShow) {
          // do not show if already shown or app is in background
          if (isFlushbarShown() || _notification != AppLifecycleState.resumed) {
            return;
          }
          alertFlushbar = createProximityAlertFlushBar(
            currentContext!,
            currentContext!
                .read<ProximityAlertsCubit>()
                .state
                .expirationTimeSec,
          );
          alertFlushbar?.show(context);
        } else if ((event is AlertExpired || event is AlertStop) &&
            isFlushbarShown()) {
          alertFlushbar?.dismiss();
        }
      },
    );

    super.initState();
  }

  @override
  void dispose() {
    alertsStreamSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Stack buildMapView(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    // acc to doc, wakelock should not be used in main but in widgets build m
    Wakelock.toggle(
        enable: context.watch<ScreenCubit>().state.screenSleepDisabled);
    return Stack(
      children: <Widget>[
        ShowcaseItem(
          showcaseKey: context.read<ShowcaseCubit>().mapKey,
          description: context.read<ShowcaseCubit>().mapDescription,
          title: 'Map',
          padding: EdgeInsets.only(bottom: -height / 3),
          child: Container(
            alignment: Alignment.bottomCenter,
            child: const MapUIGoogle(),
          ),
        ),
        const Toolbar(),
        Positioned(
          top: Sizes.toolbarHeight +
              MediaQuery.of(context).viewPadding.top +
              Sizes.mapContentMargin +
              context.read<ScreenCubit>().scaleHeight * 25,
          right: Sizes.mapContentMargin,
          child: MapOptionsToolbar(),
        ),
        AirspaceSlidingPanel(),
      ],
    );
  }

  bool isFlushbarShown() {
    return alertFlushbar != null &&
        (alertFlushbar!.isAppearing() || alertFlushbar!.isShowing());
  }

  @override
  Widget build(BuildContext context) {
    currentContext = context;
    // rebuild home page when showcase active changes
    context.read<ScreenCubit>().initScreen(context);
    context.read<ShowcaseCubit>().shouldDisplayShowcase().then((status) {
      if (status) {
        context.read<ShowcaseCubit>().startShowcase(context);
      }
    });
    return buildMapView(context);
  }
}
