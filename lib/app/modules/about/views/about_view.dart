import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:taskwarrior/app/utils/gen/assets.gen.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/about_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:taskwarrior/app/modules/home/controllers/home_controller.dart';
import 'package:taskwarrior/app/modules/home/views/theme_clipper.dart';
import 'package:taskwarrior/app/modules/profile/views/profile_view.dart';
import 'package:taskwarrior/app/utils/constants/taskwarrior_colors.dart';
import 'package:taskwarrior/app/utils/constants/taskwarrior_fonts.dart';
import 'package:taskwarrior/app/utils/constants/utilites.dart';
import 'package:taskwarrior/app/utils/theme/app_settings.dart';

class AboutView extends GetView<AboutController> {
  const AboutView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    String introduction =
        "This project aims to build an app for Taskwarrior. It is your task management app across all platforms. It helps you manage your tasks and filter them as per your needs.";

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: TaskWarriorColors.kprimaryBackgroundColor,
        title: Text(
          'About',
          style: GoogleFonts.poppins(color: TaskWarriorColors.white),
        ),
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(
            Icons.chevron_left,
            color: TaskWarriorColors.white,
          ),
        ),
      ),
      backgroundColor: AppSettings.isDarkMode
          ? TaskWarriorColors.kprimaryBackgroundColor
          : TaskWarriorColors.white,
      body: Padding(
        padding: EdgeInsets.only(top: 1.h, left: 2.w, right: 2.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                  child: SvgPicture.asset(
                Assets.svg.logo.path,
                height: 20.h,
                width: 100.w,
              )),
              SizedBox(
                height: 2.h,
              ),
              Text(
                "Taskwarrior",
                style: GoogleFonts.poppins(
                  fontWeight: TaskWarriorFonts.bold,
                  fontSize: TaskWarriorFonts.fontSizeLarge,
                  color: AppSettings.isDarkMode
                      ? TaskWarriorColors.white
                      : TaskWarriorColors.black,
                ),
              ),
              SizedBox(
                height: 2.h,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FutureBuilder<String>(
                    future: getAppInfo(),
                    builder:
                        (BuildContext context, AsyncSnapshot<String> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        final appInfoLines = snapshot.data!.split(' ');

                        return Column(
                          children: [
                            RichText(
                              text: TextSpan(
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'Version: ',
                                    style: GoogleFonts.poppins(
                                      fontWeight: TaskWarriorFonts.bold,
                                      fontSize: TaskWarriorFonts.fontSizeMedium,
                                      color: AppSettings.isDarkMode
                                          ? TaskWarriorColors.white
                                          : TaskWarriorColors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: appInfoLines[1],
                                    style: GoogleFonts.poppins(
                                      fontSize: TaskWarriorFonts.fontSizeMedium,
                                      color: AppSettings.isDarkMode
                                          ? TaskWarriorColors.white
                                          : TaskWarriorColors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 85.w,
                              child: FittedBox(
                                fit: BoxFit.fitWidth,
                                child: RichText(
                                  text: TextSpan(
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: 'Package: ',
                                        style: GoogleFonts.poppins(
                                          fontWeight: TaskWarriorFonts.bold,
                                          fontSize:
                                              TaskWarriorFonts.fontSizeMedium,
                                          color: AppSettings.isDarkMode
                                              ? TaskWarriorColors.white
                                              : TaskWarriorColors.black,
                                        ),
                                      ),
                                      TextSpan(
                                        text: appInfoLines[0],
                                        style: GoogleFonts.poppins(
                                          fontSize:
                                              TaskWarriorFonts.fontSizeMedium,
                                          color: AppSettings.isDarkMode
                                              ? TaskWarriorColors.white
                                              : TaskWarriorColors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 5.h,
              ),
              Text(
                introduction,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: TaskWarriorFonts.medium,
                  fontSize: TaskWarriorFonts.fontSizeSmall,
                  color: AppSettings.isDarkMode
                      ? TaskWarriorColors.white
                      : TaskWarriorColors.black,
                ),
              ),
              SizedBox(
                height: 6.h,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(
                    width: 40.w,
                    height: 5.h,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppSettings.isDarkMode
                            ? TaskWarriorColors.kLightSecondaryBackgroundColor
                            : TaskWarriorColors.ksecondaryBackgroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        // Launch GitHub URL.

                        String url =
                            "https://github.com/CCExtractor/taskwarrior-flutter";
                        if (!await launchUrl(Uri.parse(url))) {
                          throw Exception('Could not launch $url');
                        }
                      },
                      icon: SvgPicture.asset(Assets.svg.github.path,
                          width: 15.sp,
                          height: 15.sp,
                          colorFilter: ColorFilter.mode(
                              AppSettings.isDarkMode
                                  ? TaskWarriorColors.black
                                  : TaskWarriorColors.white,
                              BlendMode.srcIn)),
                      label: Text(
                        "GitHub",
                        style: GoogleFonts.poppins(
                          fontWeight: TaskWarriorFonts.medium,
                          fontSize: TaskWarriorFonts.fontSizeSmall,
                          color: AppSettings.isDarkMode
                              ? TaskWarriorColors.black
                              : TaskWarriorColors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40.w,
                    height: 5.h,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppSettings.isDarkMode
                            ? TaskWarriorColors.kLightSecondaryBackgroundColor
                            : TaskWarriorColors.ksecondaryBackgroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        String url = "https://ccextractor.org/";
                        if (!await launchUrl(Uri.parse(url))) {
                          throw Exception('Could not launch $url');
                        }
                      },
                      icon: SvgPicture.asset("assets/svg/link.svg",
                          width: 15.sp,
                          height: 15.sp,
                          colorFilter: ColorFilter.mode(
                              AppSettings.isDarkMode
                                  ? TaskWarriorColors.black
                                  : TaskWarriorColors.white,
                              BlendMode.srcIn)),
                      label: Text(
                        "CCExtractor",
                        style: GoogleFonts.poppins(
                          fontWeight: TaskWarriorFonts.medium,
                          fontSize: TaskWarriorFonts.fontSizeSmall,
                          color: AppSettings.isDarkMode
                              ? TaskWarriorColors.black
                              : TaskWarriorColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 2.h,
              ),
              Text(
                "Eager to enhance this project? Visit our GitHub repository.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: TaskWarriorFonts.semiBold,
                  fontSize: TaskWarriorFonts.fontSizeSmall,
                  color: AppSettings.isDarkMode
                      ? TaskWarriorColors.white
                      : TaskWarriorColors.black,
                ),
              ),
              SizedBox(
                height: 2.h,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
Future<String> getAppInfo() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  return '${packageInfo.packageName} ${packageInfo.version}';
}