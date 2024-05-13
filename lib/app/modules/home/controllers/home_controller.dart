// ignore_for_file: use_build_context_synchronously

import 'dart:collection';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import 'package:taskwarrior/app/models/json/task.dart';
import 'package:taskwarrior/app/models/storage.dart';
import 'package:taskwarrior/app/models/storage/client.dart';
import 'package:taskwarrior/app/models/tag_meta_data.dart';
import 'package:taskwarrior/app/utils/taskfunctions/comparator.dart';
import 'package:taskwarrior/app/utils/taskfunctions/projects.dart';
import 'package:taskwarrior/app/utils/taskfunctions/query.dart';
import 'package:taskwarrior/app/utils/taskfunctions/tags.dart';

class HomeController extends GetxController {
  late Storage storage;
  late bool pendingFilter;
  late bool waitingFilter;
  late String projectFilter;
  late bool tagUnion;
  late String selectedSort;
  late RxSet<String> selectedTags = <String>{}.obs;
  late List<Task> queriedTasks;
  late List<Task> searchedTasks;
  late Map<String, TagMetadata> pendingTags;
  late Map<String, ProjectNode> projects;
  bool sortHeaderVisible = false;
  bool searchVisible = false;
  var searchController = TextEditingController();
  late bool serverCertExists;

  @override
  void onInit() {
    super.onInit();
    storage = Storage(Get.arguments['profile']);
    serverCertExists = storage.guiPemFiles.serverCertExists();
    _profileSet();
  }

  void _profileSet() {
    pendingFilter = Query(storage.tabs.tab()).getPendingFilter();
    waitingFilter = Query(storage.tabs.tab()).getWaitingFilter();
    projectFilter = Query(storage.tabs.tab()).projectFilter();
    tagUnion = Query(storage.tabs.tab()).tagUnion();
    selectedSort = Query(storage.tabs.tab()).getSelectedSort();
    selectedTags(Query(storage.tabs.tab()).getSelectedTags());

    _refreshTasks();
    pendingTags = _pendingTags();
    projects = _projects();
    if (searchVisible) {
      toggleSearch();
    }
  }

  void _refreshTasks() {
    if (pendingFilter) {
      queriedTasks = storage.data
          .pendingData()
          .where((task) => task.status == 'pending')
          .toList();
    } else {
      queriedTasks = storage.data.completedData();
    }

    if (waitingFilter) {
      var currentTime = DateTime.now();
      queriedTasks = queriedTasks
          .where((task) => task.wait != null && task.wait!.isAfter(currentTime))
          .toList();
    }

    if (projectFilter.isNotEmpty) {
      queriedTasks = queriedTasks.where((task) {
        if (task.project == null) {
          return false;
        } else {
          return task.project!.startsWith(projectFilter);
        }
      }).toList();
    }

    queriedTasks = queriedTasks.where((task) {
      var tags = task.tags?.toSet() ?? {};
      if (tagUnion) {
        if (selectedTags.isEmpty) {
          return true;
        }
        return selectedTags.any((tag) => (tag.startsWith('+'))
            ? tags.contains(tag.substring(1))
            : !tags.contains(tag.substring(1)));
      } else {
        return selectedTags.every((tag) => (tag.startsWith('+'))
            ? tags.contains(tag.substring(1))
            : !tags.contains(tag.substring(1)));
      }
    }).toList();

    var sortColumn = selectedSort.substring(0, selectedSort.length - 1);
    var ascending = selectedSort.endsWith('+');
    queriedTasks.sort((a, b) {
      int result;
      if (sortColumn == 'id') {
        result = a.id!.compareTo(b.id!);
      } else {
        result = compareTasks(sortColumn)(a, b);
      }
      return ascending ? result : -result;
    });
    searchedTasks = queriedTasks;
    var searchTerm = searchController.text;
    if (searchVisible) {
      searchedTasks = searchedTasks
          .where((task) =>
              task.description.contains(searchTerm) ||
              (task.annotations?.asList() ?? []).any(
                  (annotation) => annotation.description.contains(searchTerm)))
          .toList();
    }
    pendingTags = _pendingTags();
    projects = _projects();
  }

  Map<String, TagMetadata> _pendingTags() {
    var frequency = tagFrequencies(storage.data.pendingData());
    var modified = tagsLastModified(storage.data.pendingData());
    var setOfTags = tagSet(storage.data.pendingData());
    return SplayTreeMap.of({
      for (var tag in setOfTags)
        tag: TagMetadata(
          frequency: frequency[tag] ?? 0,
          lastModified: modified[tag]!,
          selected: selectedTags
              .map(
                (filter) => filter.substring(1),
              )
              .contains(tag),
        ),
    });
  }

  Map<String, ProjectNode> _projects() {
    var frequencies = <String, int>{};
    for (var task in storage.data.pendingData()) {
      if (task.project != null) {
        if (frequencies.containsKey(task.project)) {
          frequencies[task.project!] = (frequencies[task.project] ?? 0) + 1;
        } else {
          frequencies[task.project!] = 1;
        }
      }
    }
    return SplayTreeMap.of(sparseDecoratedProjectTree(frequencies));
  }

  void togglePendingFilter() {
    Query(storage.tabs.tab()).togglePendingFilter();
    pendingFilter = Query(storage.tabs.tab()).getPendingFilter();
    _refreshTasks();
  }

  void toggleWaitingFilter() {
    Query(storage.tabs.tab()).toggleWaitingFilter();
    waitingFilter = Query(storage.tabs.tab()).getWaitingFilter();
    _refreshTasks();
  }

  void toggleProjectFilter(String project) {
    Query(storage.tabs.tab()).toggleProjectFilter(project);
    projectFilter = Query(storage.tabs.tab()).projectFilter();
    _refreshTasks();
  }

  void toggleTagUnion() {
    Query(storage.tabs.tab()).toggleTagUnion();
    tagUnion = Query(storage.tabs.tab()).tagUnion();
    _refreshTasks();
  }

  void selectSort(String sort) {
    Query(storage.tabs.tab()).setSelectedSort(sort);
    selectedSort = Query(storage.tabs.tab()).getSelectedSort();
    _refreshTasks();
  }

  void toggleTagFilter(String tag) {
    if (selectedTags.contains('+$tag')) {
      selectedTags.remove('+$tag');
      selectedTags.add('-$tag');
    } else if (selectedTags.contains('-$tag')) {
      selectedTags.remove('-$tag');
    } else {
      selectedTags.add('+$tag');
    }
    Query(storage.tabs.tab()).toggleTagFilter(tag);
    selectedTags(Query(storage.tabs.tab()).getSelectedTags());
    _refreshTasks();
  }

  Task getTask(String uuid) {
    return storage.data.getTask(uuid);
  }

  void mergeTask(Task task) {
    storage.data.mergeTask(task);

    _refreshTasks();
  }

  Future<void> synchronize(BuildContext context, bool isDialogNeeded) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'You are not connected to the internet. Please check your network connection.',
            //   style: TextStyle(
            //     color: AppSettings.isDarkMode
            //         ? TaskWarriorColors.kprimaryTextColor
            //         : TaskWarriorColors.kLightPrimaryTextColor,
            //   ),
            // ),
            // backgroundColor: AppSettings.isDarkMode
            //     ? TaskWarriorColors.ksecondaryBackgroundColor
            //     : TaskWarriorColors.kLightSecondaryBackgroundColor,
          ),
          duration: Duration(seconds: 2),
        ));
      } else {
        if (isDialogNeeded) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16.0),
                      Text(
                        "Syncing",
                        // style: GoogleFonts.poppins(
                        //   fontSize: TaskWarriorFonts.fontSizeLarge,
                        //   fontWeight: TaskWarriorFonts.bold,
                        // ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        "Please wait...",
                        // style: GoogleFonts.poppins(
                        //   fontSize: TaskWarriorFonts.fontSizeSmall,
                        //   fontWeight: TaskWarriorFonts.regular,
                        // ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        var header = await storage.home.synchronize(await client());
        _refreshTasks();
        pendingTags = _pendingTags();
        projects = _projects();

        if (isDialogNeeded) {
          Get.back();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${header['code']}: ${header['status']}',
              // style: TextStyle(
              //   color: AppSettings.isDarkMode
              //       ? TaskWarriorColors.kprimaryTextColor
              //       : TaskWarriorColors.kLightPrimaryTextColor,
              // ),
            ),
            // backgroundColor: AppSettings.isDarkMode
            //     ? TaskWarriorColors.ksecondaryBackgroundColor
            //     : TaskWarriorColors.kLightSecondaryBackgroundColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, trace) {
      if (isDialogNeeded) {
        Get.back();
      }
      logError(e, trace);
    }
  }

  void toggleSortHeader() {
    sortHeaderVisible = !sortHeaderVisible;
  }

  void toggleSearch() {
    searchVisible = !searchVisible;
    if (!searchVisible) {
      searchedTasks = queriedTasks;
      searchController.text = '';
    }
  }

  void search(String term) {
    searchedTasks = queriedTasks
        .where(
          (task) => task.description.toLowerCase().contains(term.toLowerCase()),
        )
        .toList();
  }

  void setInitialTabIndex(int index) {
    storage.tabs.setInitialTabIndex(index);
    pendingFilter = Query(storage.tabs.tab()).getPendingFilter();
    waitingFilter = Query(storage.tabs.tab()).getWaitingFilter();
    selectedSort = Query(storage.tabs.tab()).getSelectedSort();
    selectedTags(Query(storage.tabs.tab()).getSelectedTags());
    projectFilter = Query(storage.tabs.tab()).projectFilter();
    _refreshTasks();
  }

  void addTab() {
    storage.tabs.addTab();
  }

  List<String> tabUuids() {
    return storage.tabs.tabUuids();
  }

  int initialTabIndex() {
    return storage.tabs.initialTabIndex();
  }

  void removeTab(int index) {
    storage.tabs.removeTab(index);
    pendingFilter = Query(storage.tabs.tab()).getPendingFilter();
    waitingFilter = Query(storage.tabs.tab()).getWaitingFilter();
    selectedSort = Query(storage.tabs.tab()).getSelectedSort();
    selectedTags(Query(storage.tabs.tab()).getSelectedTags());
    _refreshTasks();
  }

  void renameTab({
    required String tab,
    required String name,
  }) {
    storage.tabs.renameTab(tab: tab, name: name);
  }

  String? tabAlias(String tabUuid) {
    return storage.tabs.alias(tabUuid);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
