import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../bloc/showcase_cubit.dart';
import '../../bloc/sliders_cubit.dart';
import '../app/app_scaffold.dart';
import 'home_body.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // hide keyboard
      child: ShowCaseWidget(
        onStart: (index, key) {
          context.read<ShowcaseCubit>().onKeyStart(context, index, key);
        },
        onComplete: (index, key) {
          context.read<ShowcaseCubit>().onKeyComplete(context, index, key);
        },
        onFinish: () {
          context.read<ShowcaseCubit>().onShowcaseFinish(context);
        },
        builder: Builder(
          builder: (context) => AnnotatedRegion(
            value: SystemUiOverlayStyle.dark,
            child: WillPopScope(
              onWillPop: () async {
                final cubit = context.read<SlidersCubit>();
                final state = cubit.state;
                if (state.showDroneDetail) {
                  await cubit.setShowDroneDetail(show: false);
                  return false;
                } else if (cubit.isPanelOpened()) {
                  await context.read<SlidersCubit>().animatePanelToSnapPoint();
                  return false;
                }
                return true;
              },
              child: AppScaffold(
                child: HomeBody(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
