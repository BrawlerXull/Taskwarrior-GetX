import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:taskwarrior/app/themes/themes.dart';

import 'app/routes/app_pages.dart';

void main() {
  runApp(
    GetMaterialApp(
      title: "Application",
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
        theme: lightTheme,
        darkTheme: darkTheme,
    ),
  );
}
