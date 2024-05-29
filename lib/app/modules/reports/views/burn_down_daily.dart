import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:taskwarrior/app/models/chart.dart';
import 'package:taskwarrior/app/models/json/task.dart';
import 'package:taskwarrior/app/models/storage.dart';
import 'package:taskwarrior/app/modules/home/controllers/home_controller.dart';
import 'package:taskwarrior/app/modules/reports/controllers/reports_controller.dart';
import 'package:taskwarrior/app/modules/splash/controllers/splash_controller.dart';
import 'package:taskwarrior/app/utils/constants/taskwarrior_colors.dart';
import 'package:taskwarrior/app/utils/constants/taskwarrior_fonts.dart';
import 'package:taskwarrior/app/utils/constants/utilites.dart';
import 'package:taskwarrior/app/utils/gen/fonts.gen.dart';
import 'package:taskwarrior/app/utils/theme/app_settings.dart';

class BurnDownDaily extends StatelessWidget {
  final ReportsController reportsController;
  const BurnDownDaily({super.key, required this.reportsController});

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SizedBox(
              height: height * 0.6,
              child: Obx(
                () => SfCartesianChart(
                  primaryXAxis: CategoryAxis(
                    title: AxisTitle(
                      text: 'Day - Month',
                      // textStyle: GoogleFonts.poppins(
                      // fontWeight: TaskWarriorFonts.bold,
                      // color: AppSettings.isDarkMode ? Colors.white : Colors.black,
                      // fontSize: TaskWarriorFonts.fontSizeSmall,
                      // ),
                      textStyle: TextStyle(
                        fontFamily: FontFamily.poppins,
                        fontWeight: TaskWarriorFonts.bold,
                        color: AppSettings.isDarkMode
                            ? Colors.white
                            : Colors.black,
                        fontSize: TaskWarriorFonts.fontSizeSmall,
                      ),
                    ),
                  ),
                  primaryYAxis: NumericAxis(
                    title: AxisTitle(
                      text: 'Tasks',
                      // textStyle: GoogleFonts.poppins(
                      //   fontWeight: TaskWarriorFonts.bold,
                      //   fontSize: TaskWarriorFonts.fontSizeSmall,
                      //   color: AppSettings.isDarkMode ? Colors.white : Colors.black,
                      // ),
                      textStyle: TextStyle(
                        fontFamily: FontFamily.poppins,
                        fontWeight: TaskWarriorFonts.bold,
                        color: AppSettings.isDarkMode
                            ? Colors.white
                            : Colors.black,
                        fontSize: TaskWarriorFonts.fontSizeSmall,
                      ),
                    ),
                  ),
                  tooltipBehavior:
                      reportsController.dailyBurndownTooltipBehaviour,
                  series: <ChartSeries>[
                    /// This is the completed tasks
                    StackedColumnSeries<ChartData, String>(
                      groupName: 'Group A',
                      enableTooltip: true,
                      color: TaskWarriorColors.green,
                      dataSource: reportsController.dailyInfo.entries
                          .map((entry) => ChartData(
                                entry.key,
                                entry.value['pending'] ?? 0,
                                entry.value['completed'] ?? 0,
                              ))
                          .toList(),
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.y2,
                      name: 'Completed',
                    ),

                    /// This is the pending tasks
                    StackedColumnSeries<ChartData, String>(
                      groupName: 'Group A',
                      color: TaskWarriorColors.yellow,
                      enableTooltip: true,
                      dataSource: reportsController.dailyInfo.entries
                          .map((entry) => ChartData(
                                entry.key,
                                entry.value['pending'] ?? 0,
                                entry.value['completed'] ?? 0,
                              ))
                          .toList(),
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.y1,
                      name: 'Pending',
                    ),
                  ],
                ),
              )),
        ),
        const CommonChartIndicator(
          title: 'Daily Burndown Chart',
        ),
      ],
    );
  }
}

class CommonChartIndicator extends StatelessWidget {
  final String title;
  const CommonChartIndicator({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              // style: GoogleFonts.poppins(
              //   fontWeight: TaskWarriorFonts.bold,
              //   fontSize: TaskWarriorFonts.fontSizeMedium,
              //   color: AppSettings.isDarkMode
              //       ? TaskWarriorColors.white
              //       : TaskWarriorColors.black,
              // ),
              style: TextStyle(
                fontFamily: FontFamily.poppins,
                fontWeight: TaskWarriorFonts.bold,
                color: AppSettings.isDarkMode ? Colors.white : Colors.black,
                fontSize: TaskWarriorFonts.fontSizeMedium,
              ),
            )
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Container(
                  height: 20,
                  width: 80,
                  decoration: BoxDecoration(color: TaskWarriorColors.green),
                ),
                Text(
                  "Completed",
                  // style: GoogleFonts.poppins(
                  //   fontWeight: TaskWarriorFonts.regular,
                  //   fontSize: TaskWarriorFonts.fontSizeMedium,
                  //   color: AppSettings.isDarkMode
                  //       ? TaskWarriorColors.white
                  //       : TaskWarriorColors.black,
                  // ),
                  style: TextStyle(
                    fontFamily: FontFamily.poppins,
                    fontWeight: TaskWarriorFonts.regular,
                    color: AppSettings.isDarkMode ? Colors.white : Colors.black,
                    fontSize: TaskWarriorFonts.fontSizeSmall,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Container(
                  height: 20,
                  width: 80,
                  decoration: BoxDecoration(color: TaskWarriorColors.yellow),
                ),
                Text(
                  "Pending",
                  // style: GoogleFonts.poppins(
                  //   fontWeight: TaskWarriorFonts.regular,
                  //   fontSize: TaskWarriorFonts.fontSizeMedium,
                  //   color: AppSettings.isDarkMode
                  //       ? TaskWarriorColors.white
                  //       : TaskWarriorColors.black,
                  // ),
                  style: TextStyle(
                    fontFamily: FontFamily.poppins,
                    fontWeight: TaskWarriorFonts.regular,
                    color: AppSettings.isDarkMode ? Colors.white : Colors.black,
                    fontSize: TaskWarriorFonts.fontSizeSmall,
                  ),
                ),
              ],
            )
          ],
        ),
      ],
    );
  }
}
