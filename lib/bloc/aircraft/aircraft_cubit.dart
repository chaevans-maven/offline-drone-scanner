import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_opendroneid/models/message_pack.dart';
import 'package:flutter_opendroneid/pigeon.dart' as pigeon;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:localstorage/localstorage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '/utils/csvlogger.dart';
import '../../utils/utils.dart';
import '../sliders_cubit.dart';
import 'aircraft_expiration_cubit.dart';

part 'aircraft_state.dart';

class AircraftCubit extends Cubit<AircraftState> {
  Timer? _refreshTimer;
  final AircraftExpirationCubit expirationCubit;
  // storage for user-given labels
  final LocalStorage storage = LocalStorage('dronescanner');

  static const uiUpdateIntervalMs = 200;

  // data for showcase
  final List<MessagePack> _packs = [
    MessagePack(
      macAddress: '00:00:5e:00:53:ae',
      lastUpdate: DateTime.now(),
      locationMessage: pigeon.LocationMessage(
        receivedTimestamp: DateTime.now().microsecondsSinceEpoch,
        macAddress: '00:00:5e:00:53:ae',
        latitude: 50.073058,
        heightType: pigeon.HeightType.Ground,
        direction: 1,
        speedAccuracy: pigeon.SpeedAccuracy.meter_per_second_0_3,
        verticalAccuracy: pigeon.VerticalAccuracy.meters_1,
        horizontalAccuracy: pigeon.HorizontalAccuracy.kilometers_18_52,
        speedHorizontal: 0.2,
        speedVertical: 0.5,
        longitude: 14.411540,
        height: 10,
        status: pigeon.AircraftStatus.Airborne,
        rssi: -100,
        source: pigeon.MessageSource.BluetoothLegacy,
      ),
      basicIdMessage: pigeon.BasicIdMessage(
        macAddress: '00:00:5e:00:53:ae',
        receivedTimestamp: DateTime.now().microsecondsSinceEpoch,
        uasId: '52426900931WDHW83',
        idType: pigeon.IdType.UTM_Assigned_ID,
        uaType: pigeon.UaType.Helicopter_or_Multirotor,
        rssi: -90,
        source: pigeon.MessageSource.BluetoothLegacy,
      ),
      operatorIdMessage: pigeon.OperatorIdMessage(
        macAddress: '00:00:5e:00:53:ae',
        receivedTimestamp: DateTime.now().microsecondsSinceEpoch,
        operatorId: 'FIN87astrdge12k8-xyz',
        rssi: -60,
        source: pigeon.MessageSource.BluetoothLegacy,
      ),
      selfIdMessage: pigeon.SelfIdMessage(
        macAddress: '00:00:5e:00:53:ae',
        receivedTimestamp: DateTime.now().microsecondsSinceEpoch,
        descriptionType: 0,
        operationDescription: 'This is very secret operation!',
      ),
    ),
  ];

  AircraftCubit(this.expirationCubit)
      : super(
          AircraftState(
            packHistory: <String, List<MessagePack>>{},
            aircraftLabels: <String, String>{},
          ),
        ) {
    expirationCubit.deleteCallback = deletePack;
    fetchSavedAircraftLabels();
  }

  // timer used to notify UI
  void initEmitTimer({
    Duration duration = const Duration(
      milliseconds: uiUpdateIntervalMs,
    ),
  }) {
    stopEmitTimer();
    _refreshTimer = Timer.periodic(
      duration,
      (_) => aircraftUpdate,
    );
  }

  void aircraftUpdate() {
    emit(
      AircraftStateUpdate(
        packHistory: state.packHistory(),
        aircraftLabels: state.aircraftLabels,
      ),
    );
  }

  void stopEmitTimer() {
    if (_refreshTimer != null) {
      _refreshTimer!.cancel();
      _refreshTimer = null;
    }
  }

  //Retrieves the labels stored persistently locally on the device
  Future<void> fetchSavedAircraftLabels() async {
    final ready = await storage.ready;
    if (ready) {
      var labels = storage.getItem('labels');
      final labelsMap = <String, String>{};
      if (labels != null) {
        (json.decode(labels as String) as Map<String, dynamic>)
            .forEach((key, value) => labelsMap[key] = value as String);
      }
      emit(
        state.copyWith(
          aircraftLabels: labelsMap,
        ),
      );
    }
  }

  // Stores the label persistently locally on the device
  Future<void> addAircraftLabel(String mac, String label) async {
    var labels = state.aircraftLabels;
    labels[mac] = label;
    emit(
      state.copyWith(aircraftLabels: labels),
    );
    await _saveLabels();
  }

  // deletes locally stored label for aircraft with given mac
  Future<void> deleteAircraftLabel(String mac) async {
    var labels = state.aircraftLabels;
    labels.remove(mac);
    emit(
      state.copyWith(aircraftLabels: labels),
    );
    await _saveLabels();
  }

  String? getAircraftLabel(String mac) {
    return state.aircraftLabels[mac];
  }

  Future<void> _saveLabels() async {
    await storage.setItem('labels', json.encode(state.aircraftLabels));
    await fetchSavedAircraftLabels();
  }

  MessagePack? findByMacAddress(String mac) {
    return state.packHistory()[mac]?.last;
  }

  MessagePack? findByUasID(String uasId) {
    final packs = state.packHistory().values.firstWhere(
        (packList) =>
            packList.any((element) => element.basicIdMessage?.uasId == uasId),
        orElse: () => []);
    return packs.isEmpty ? null : packs.last;
  }

  List<MessagePack>? packsForDevice(String mac) {
    return state.packHistory()[mac];
  }

  Future<void> clear() async {
    emit(
      AircraftStateUpdate(
        packHistory: {},
        aircraftLabels: state.aircraftLabels,
      ),
    );
  }

  Future<void> addPack(MessagePack pack) async {
    try {
      // set received time
      pack.locationMessage?.receivedTimestamp =
          DateTime.now().millisecondsSinceEpoch;
      final data = state._packHistory;
      // new pack
      if (!data.containsKey(pack.macAddress)) {
        data[pack.macAddress] = [pack];
      } else {
        // update of already seen aircraft
        data[pack.macAddress]?.add(pack);
        // remove old and start new expiry timer
        expirationCubit.removeTimer(pack.macAddress);
      }
      expirationCubit.addTimer(pack.macAddress);
      emit(
        AircraftStateBuffering(
          packHistory: data,
          aircraftLabels: state.aircraftLabels,
        ),
      );
    } on Exception {
      rethrow;
    }
  }

  String get showcaseDummyMac {
    return _packs[0].macAddress;
  }

  Future<MessagePack?> addShowcaseDummyPack() async {
    await clear();
    final pack = _packs[0];
    pack.locationMessage?.receivedTimestamp =
        DateTime.now().millisecondsSinceEpoch;
    try {
      final data = state.packHistory();
      data[pack.macAddress] = [pack];
      emit(
        AircraftStateUpdate(
          packHistory: data,
          aircraftLabels: state.aircraftLabels,
        ),
      );
    } on Exception {
      rethrow;
    }
    return pack;
  }

  Future<void> removeShowcaseDummyPack() async {
    final pack = _packs[0];
    await deletePack(pack.macAddress);
  }

  Future<void> deletePack(String mac) async {
    expirationCubit.removeTimer(mac);

    final data = state._packHistory;
    data.removeWhere((key, _) => mac == key);
    emit(
      AircraftStateUpdate(
        packHistory: data,
        aircraftLabels: state.aircraftLabels,
      ),
    );
  }

  Future<bool> exportPacksToCSV() async {
    final hasPerm = await checkStoragePermission();
    if (!hasPerm) {
      return false;
    }
    var csv = '';
    state.packHistory().forEach((key, value) {
      final csvData = CSVLogger.createCSV(value, includeHeader: csv == '');
      csv += '\n';
      csv += const ListToCsvConverter().convert(csvData);
    });
    if (csv.isEmpty) return false;
    return await _shareExportFile(csv, 'all');
  }

  Future<bool> exportPackToCSV({
    required String mac,
  }) async {
    if (state.packHistory()[mac] == null) return false;
    // request permission
    final hasPermission = await checkStoragePermission();
    if (!hasPermission) return false;

    final csvData = CSVLogger.createCSV(state.packHistory()[mac]!);
    final csv = const ListToCsvConverter().convert(csvData);
    if (csv.isEmpty) return false;

    /// Write to a file
    late final String uasId;
    if (state.packHistory()[mac]!.isNotEmpty &&
        state.packHistory()[mac]?.last.basicIdMessage != null &&
        state.packHistory()[mac]?.last.basicIdMessage?.uasId != null) {
      uasId = state.packHistory()[mac]!.last.basicIdMessage!.uasId;
    } else {
      uasId = mac;
    }
    return await _shareExportFile(csv, uasId);
  }

  Future<bool> checkStoragePermission() async {
    if (Platform.isIOS) {
      return _storagePermissionCheck();
    } else {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      // Since Android SDK 33, storage is not used
      if (androidInfo.version.sdkInt >= 33) {
        return await _mediaStoragePermissionCheck();
      } else {
        return await _storagePermissionCheck();
      }
    }
  }

  Future<bool> _storagePermissionCheck() async {
    final storage = await Permission.storage.status.isGranted;
    if (!storage) {
      return await Permission.storage.request().isGranted;
    }
    return storage;
  }

  Future<bool> _mediaStoragePermissionCheck() async {
    var videos = await Permission.videos.status.isGranted;
    var photos = await Permission.photos.status.isGranted;
    if (!videos || !photos) {
      // request at once, will produce 1 dialog
      videos = await Permission.videos.request().isGranted;
      photos = await Permission.videos.request().isGranted;
    }
    return videos && photos;
  }

  Future<bool> _shareExportFile(String csv, String name) async {
    final directory = await getApplicationDocumentsDirectory();

    final pathOfTheFileToWrite =
        '${directory.path}/drone_scanner_export_$name.csv';
    var file = File(pathOfTheFileToWrite);
    file = await file.writeAsString(csv);

    late final result;
    if (Platform.isAndroid) {
      result = await Share.shareXFiles([XFile(pathOfTheFileToWrite)],
          subject: 'Drone Scanner Export', text: 'Your Remote ID Data');
    } else {
      result = await Share.shareXFiles([XFile(pathOfTheFileToWrite)]);
    }
    if (result.status == ShareResultStatus.success) {
      return true;
    } else {
      return false;
    }
  }

  void applyState(AircraftState state) {
    emit(state);
  }
}
