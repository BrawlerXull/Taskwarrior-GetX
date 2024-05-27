import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taskwarrior/app/models/json/task.dart';
import 'package:taskwarrior/app/models/storage.dart';
import 'package:taskwarrior/app/modules/splash/controllers/splash_controller.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';



class ReportsController extends GetxController with GetTickerProviderStateMixin {
  late TabController tabController;
  final daily = GlobalKey();
  final weekly = GlobalKey();
  final monthly = GlobalKey();

  var isSaved = false.obs;
  late TutorialCoachMark tutorialCoachMark;

  var selectedIndex = 0.obs;
  var allData = <Task>[].obs;
  late Storage storage;

  // void _initReportsTour() {
  //   tutorialCoachMark = TutorialCoachMark(
  //     targets: reportsDrawer(
  //       daily: daily,
  //       weekly: weekly,
  //       monthly: monthly,
  //     ),
  //     colorShadow: TaskWarriorColors.black,
  //     paddingFocus: 10,
  //     opacityShadow: 0.8,
  //     hideSkip: true,
  //     onFinish: () {
  //       SaveReportsTour().saveReportsTourStatus();
  //     },
  //   );
  // }

  // void showReportsTour() {
  //   Future.delayed(
  //     const Duration(seconds: 2),
  //     () {
  //       SaveReportsTour().getReportsTourStatus().then((value) => {
  //             if (value == false)
  //               {
  //                 tutorialCoachMark.show(context: Get.context!),
  //               }
  //             else
  //               {
  //                 // ignore: avoid_print
  //                 print('User has seen this page'),
  //               }
  //           });
  //     },
  //   );
  // }

  @override
  void onInit() {
    super.onInit();
    // _initReportsTour();
    // showReportsTour();

    tabController = TabController(length: 3, vsync: this);

    Future.delayed(Duration.zero, () {
      var currentProfile = Get.find<SplashController>().currentProfile;
      Directory baseDirectory = Get.find<SplashController>().baseDirectory();
      storage = Storage(Directory('${baseDirectory.path}/profiles/$currentProfile'));

      allData.value = storage.data.allData();
    });
  }
}
