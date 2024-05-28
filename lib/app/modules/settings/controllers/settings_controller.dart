import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/state_manager.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskwarrior/app/utils/constants/taskwarrior_fonts.dart';
import 'package:taskwarrior/app/utils/constants/utilites.dart';

import '../controllers/settings_controller.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:taskwarrior/app/models/filters.dart';
import 'package:taskwarrior/app/modules/detailRoute/views/detail_route_view.dart';

import 'package:taskwarrior/app/modules/home/views/filter_drawer_home_page.dart';
import 'package:taskwarrior/app/modules/home/views/tasks_builder.dart';
import 'package:taskwarrior/app/modules/manageTaskServer/views/manage_task_server_view.dart';
import 'package:taskwarrior/app/services/tag_filter.dart';
import 'package:taskwarrior/app/utils/constants/palette.dart';
import 'package:taskwarrior/app/utils/constants/taskwarrior_colors.dart';
import 'package:taskwarrior/app/utils/gen/fonts.gen.dart';
import 'package:taskwarrior/app/utils/taskserver/taskserver.dart';
import 'package:taskwarrior/app/utils/home_path/home_path.dart' as rc;
import 'package:taskwarrior/app/utils/theme/app_settings.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

import 'package:get/get.dart';
import 'package:taskwarrior/app/modules/splash/controllers/splash_controller.dart';

class SettingsController extends GetxController {
  RxBool isMovingDirectory = false.obs;

  Future<String> getBaseDirectory() async {
    SplashController profilesWidget = Get.find<SplashController>();
    Directory baseDirectory = profilesWidget.baseDirectory();
    Directory defaultDirectory = await profilesWidget.getDefaultDirectory();
    if (baseDirectory.path == defaultDirectory.path) {
      return 'Default';
    } else {
      return baseDirectory.path;
    }
  }

  void pickDirectory(BuildContext context) {
    FilePicker.platform.getDirectoryPath().then((value) async {
      if (value != null) {
        isMovingDirectory.value = true;
        update();
        // InheritedProfiles profilesWidget = ProfilesWidget.of(context);
        var profilesWidget = Get.find<SplashController>();
        Directory source = profilesWidget.baseDirectory();
        Directory destination = Directory(value);
        moveDirectory(source.path, destination.path).then((value) async {
          isMovingDirectory.value = false;
          update();
          if (value == "same") {
            return;
          } else if (value == "success") {
            profilesWidget.setBaseDirectory(destination);
            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.setString('baseDirectory', destination.path);
          } else {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return Utils.showAlertDialog(
                  title: Text(
                    'Error',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: TaskWarriorFonts.fontSizeMedium,
                      color: AppSettings.isDarkMode
                          ? TaskWarriorColors.white
                          : TaskWarriorColors.black,
                    ),
                  ),
                  content: Text(
                    value == "nested"
                        ? "Cannot move to a nested directory"
                        : value == "not-empty"
                            ? "Destination directory is not empty"
                            : "An error occurred",
                    style: GoogleFonts.poppins(
                      color: TaskWarriorColors.grey,
                      fontSize: TaskWarriorFonts.fontSizeSmall,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'OK',
                        style: GoogleFonts.poppins(
                          color: AppSettings.isDarkMode
                              ? TaskWarriorColors.white
                              : TaskWarriorColors.black,
                        ),
                      ),
                    )
                  ],
                );
              },
            );
          }
        });
      }
    });
  }

  Future<String> moveDirectory(String fromDirectory, String toDirectory) async {
    if (path.canonicalize(fromDirectory) == path.canonicalize(toDirectory)) {
      return "same";
    }

    if (path.isWithin(fromDirectory, toDirectory)) {
      return "nested";
    }

    Directory toDir = Directory(toDirectory);
    final length = await toDir.list().length;
    if (length > 0) {
      return "not-empty";
    }

    await moveDirectoryRecurse(fromDirectory, toDirectory);
    return "success";
  }

  Future<void> moveDirectoryRecurse(
      String fromDirectory, String toDirectory) async {
    Directory fromDir = Directory(fromDirectory);
    Directory toDir = Directory(toDirectory);

    // Create the toDirectory if it doesn't exist
    await toDir.create(recursive: true);

    // Loop through each file and directory and move it to the toDirectory
    await for (final entity in fromDir.list()) {
      if (entity is File) {
        // If it's a file, move it to the toDirectory
        File file = entity;
        String newPath = path.join(
            toDirectory, path.relative(file.path, from: fromDirectory));
        await File(newPath).writeAsBytes(await file.readAsBytes());
        await file.delete();
      } else if (entity is Directory) {
        // If it's a directory, create it in the toDirectory and recursively move its contents
        Directory dir = entity;
        String newPath = path.join(
            toDirectory, path.relative(dir.path, from: fromDirectory));
        Directory newDir = Directory(newPath);
        await newDir.create(recursive: true);
        await moveDirectoryRecurse(dir.path, newPath);
        await dir.delete();
      }
    }
  }

  RxBool isSyncOnStartActivel = false.obs;
  RxBool isSyncOnTaskCreateActivel = false.obs;
  RxBool delaytask = false.obs;
  RxBool change24hr = false.obs;

  @override
  void onInit() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    isSyncOnStartActivel.value = prefs.getBool('sync-onStart') ?? false;
    isSyncOnTaskCreateActivel.value = prefs.getBool('sync-OnTaskCreate') ?? false;
    delaytask.value = prefs.getBool('delaytask') ?? false;
    change24hr.value = prefs.getBool('24hourformate') ?? false;
    super.onInit();
  }
}
