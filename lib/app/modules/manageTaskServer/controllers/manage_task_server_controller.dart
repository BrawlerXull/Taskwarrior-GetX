import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';
import 'package:taskwarrior/app/models/storage.dart';
import 'package:taskwarrior/app/modules/home/controllers/home_controller.dart';
import 'package:taskwarrior/app/modules/splash/controllers/splash_controller.dart';
import 'package:taskwarrior/app/utils/home_path/home_path.dart' as rc;
import 'package:taskwarrior/app/utils/taskserver/taskserver.dart';

class ManageTaskServerController extends GetxController {
  final HomeController homeController = Get.find<HomeController>();
  final SplashController splashController = Get.find<SplashController>();
  late RxString profile;
  late Storage storage;
  late RxString alias;
  late Server? server;
  late Credentials? credentials;

  @override
  void onInit() {
    super.onInit();
    storage = homeController.storage;
    profile.value = storage.profile.uri.pathSegments
        .lastWhere((segment) => segment.isNotEmpty);
    alias = RxString(splashController.profilesMap[profile.value] ?? '');
  }

  Future<void> setConfigurationFromFixtureForDebugging() async {
    try {
      var contents = await rootBundle.loadString('assets/.taskrc');
      rc.Taskrc(storage.home.home).addTaskrc(contents);
      var taskrc = Taskrc.fromString(contents);
      server = taskrc.server;
      credentials = taskrc.credentials;
      for (var entry in {
        'taskd.certificate': '.task/first_last.cert.pem',
        'taskd.key': '.task/first_last.key.pem',
        'taskd.ca': '.task/ca.cert.pem',
        // 'server.cert': '.task/server.cert.pem',
      }.entries) {
        var contents = await rootBundle.loadString('assets/${entry.value}');
        storage.guiPemFiles.addPemFile(
          key: entry.key,
          contents: contents,
          name: entry.value.split('/').last,
        );
      }
    } catch (e) {
      logError(e);
    }
  }

  
}
