// ignore_for_file: use_build_context_synchronously, unrelated_type_equality_checks

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
  final Storage _storage = Get.arguments['profile'];
  final RxBool pendingFilter = false.obs;
  final RxBool waitingFilter = false.obs;
  final RxString projectFilter = ''.obs;
  final RxBool tagUnion = false.obs;
  final RxString selectedSort = ''.obs;
  final RxSet<String> selectedTags = <String>{}.obs;
  final RxList<Task> queriedTasks = <Task>[].obs;
  final RxList<Task> searchedTasks = <Task>[].obs;
  final RxMap<String, TagMetadata> pendingTags = <String, TagMetadata>{}.obs;
  final RxMap<String, ProjectNode> projects = <String, ProjectNode>{}.obs;
  final RxBool sortHeaderVisible = false.obs;
  final RxBool searchVisible = false.obs;
  final TextEditingController searchController = TextEditingController();
  late RxBool serverCertExists;

  @override
  void onInit() {
    super.onInit();
    serverCertExists = RxBool(_storage.guiPemFiles.serverCertExists());
    _profileSet();
  }

  void _profileSet() {
    pendingFilter.value = Query(_storage.tabs.tab()).getPendingFilter();
    waitingFilter.value = Query(_storage.tabs.tab()).getWaitingFilter();
    projectFilter.value = Query(_storage.tabs.tab()).projectFilter();
    tagUnion.value = Query(_storage.tabs.tab()).tagUnion();
    selectedSort.value = Query(_storage.tabs.tab()).getSelectedSort();
    selectedTags.addAll(Query(_storage.tabs.tab()).getSelectedTags());

    _refreshTasks();
    pendingTags.value = _pendingTags();
    projects.value = _projects();
    if (searchVisible.value) {
      toggleSearch();
    }
  }

  void _refreshTasks() {
    if (pendingFilter.value) {
      queriedTasks.value = _storage.data
          .pendingData()
          .where((task) => task.status == 'pending')
          .toList();
    } else {
      queriedTasks.value = _storage.data.completedData();
    }

    if (waitingFilter.value) {
      var currentTime = DateTime.now();
      queriedTasks.value = queriedTasks
          .where((task) => task.wait != null && task.wait!.isAfter(currentTime))
          .toList();
    }

    if (projectFilter.value.isNotEmpty) {
      queriedTasks.value = queriedTasks.where((task) {
        if (task.project == null) {
          return false;
        } else {
          return task.project!.startsWith(projectFilter.value);
        }
      }).toList();
    }

    queriedTasks.value = queriedTasks.where((task) {
      var tags = task.tags?.toSet() ?? {};
      if (tagUnion.value) {
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

    var sortColumn =
        selectedSort.value.substring(0, selectedSort.value.length - 1);
    var ascending = selectedSort.value.endsWith('+');
    queriedTasks.sort((a, b) {
      int result;
      if (sortColumn == 'id') {
        result = a.id!.compareTo(b.id!);
      } else {
        result = compareTasks(sortColumn)(a, b);
      }
      return ascending ? result : -result;
    });

    searchedTasks.assignAll(queriedTasks);
    var searchTerm = searchController.text;
    if (searchVisible.value) {
      searchedTasks.value = searchedTasks
          .where((task) =>
              task.description.contains(searchTerm) ||
              (task.annotations?.asList() ?? []).any(
                  (annotation) => annotation.description.contains(searchTerm)))
          .toList();
    }
    pendingTags.value = _pendingTags();
    projects.value = _projects();
  }

  Map<String, TagMetadata> _pendingTags() {
    var frequency = tagFrequencies(_storage.data.pendingData());
    var modified = tagsLastModified(_storage.data.pendingData());
    var setOfTags = tagSet(_storage.data.pendingData());

    return SplayTreeMap.of({
      for (var tag in setOfTags)
        tag: TagMetadata(
          frequency: frequency[tag] ?? 0,
          lastModified: modified[tag]!,
          selected: selectedTags.contains('+$tag'),
        ),
    });
  }

  Map<String, ProjectNode> _projects() {
    var frequencies = <String, int>{};
    for (var task in _storage.data.pendingData()) {
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
    Query(_storage.tabs.tab()).togglePendingFilter();
    pendingFilter.value = Query(_storage.tabs.tab()).getPendingFilter();
    _refreshTasks();
  }

  void toggleWaitingFilter() {
    Query(_storage.tabs.tab()).toggleWaitingFilter();
    waitingFilter.value = Query(_storage.tabs.tab()).getWaitingFilter();
    _refreshTasks();
  }

  void toggleProjectFilter(String project) {
    Query(_storage.tabs.tab()).toggleProjectFilter(project);
    projectFilter.value = Query(_storage.tabs.tab()).projectFilter();
    _refreshTasks();
  }

  void toggleTagUnion() {
    Query(_storage.tabs.tab()).toggleTagUnion();
    tagUnion.value = Query(_storage.tabs.tab()).tagUnion();
    _refreshTasks();
  }

  void selectSort(String sort) {
    Query(_storage.tabs.tab()).setSelectedSort(sort);
    selectedSort.value = Query(_storage.tabs.tab()).getSelectedSort();
    _refreshTasks();
  }

  void toggleTagFilter(String tag) {
    if (selectedTags.contains('+$tag')) {
      selectedTags
        ..remove('+$tag')
        ..add('-$tag');
    } else if (selectedTags.contains('-$tag')) {
      selectedTags.remove('-$tag');
    } else {
      selectedTags.add('+$tag');
    }
    Query(_storage.tabs.tab()).toggleTagFilter(tag);
    selectedTags.addAll(Query(_storage.tabs.tab()).getSelectedTags());
    _refreshTasks();
  }

  Task getTask(String uuid) {
    return _storage.data.getTask(uuid);
  }

  void mergeTask(Task task) {
    _storage.data.mergeTask(task);

    _refreshTasks();
  }

  Future<void> synchronize(BuildContext context, bool isDialogNeeded) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
              'You are not connected to the internet. Please check your network connection.',
              style: TextStyle(
                  // color: AppSettings.isDarkMode
                  //     ? TaskWarriorColors.kprimaryTextColor
                  //     : TaskWarriorColors.kLightPrimaryTextColor,
                  ),
            ),
            // backgroundColor: AppSettings.isDarkMode
            //     ? TaskWarriorColors.ksecondaryBackgroundColor
            //     : TaskWarriorColors.kLightSecondaryBackgroundColor,
            duration: Duration(seconds: 2)));
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

        var header = await _storage.home.synchronize(await client());
        _refreshTasks();
        pendingTags.value = _pendingTags();
        projects.value = _projects();

        if (isDialogNeeded) {
          Get.back();
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              '${header['code']}: ${header['status']}',
              style: const TextStyle(
                  // color: AppSettings.isDarkMode
                  //     ? TaskWarriorColors.kprimaryTextColor
                  //     : TaskWarriorColors.kLightPrimaryTextColor,
                  ),
            ),
            // backgroundColor: AppSettings.isDarkMode
            //     ? TaskWarriorColors.ksecondaryBackgroundColor
            //     : TaskWarriorColors.kLightSecondaryBackgroundColor,
            duration: const Duration(seconds: 2)));
      }
    } catch (e, trace) {
      if (isDialogNeeded) {
        Get.back();
      }
      logError(e, trace);
    }
  }

  void toggleSortHeader() {
    sortHeaderVisible.value = !sortHeaderVisible.value;
  }

  void toggleSearch() {
    searchVisible.value = !searchVisible.value;
    if (!searchVisible.value) {
      searchedTasks.assignAll(queriedTasks);
      searchController.text = '';
    }
  }

  void search(String term) {
    searchedTasks.assignAll(
      queriedTasks
          .where(
            (task) =>
                task.description.toLowerCase().contains(term.toLowerCase()),
          )
          .toList(),
    );
  }

  void setInitialTabIndex(int index) {
    _storage.tabs.setInitialTabIndex(index);
    pendingFilter.value = Query(_storage.tabs.tab()).getPendingFilter();
    waitingFilter.value = Query(_storage.tabs.tab()).getWaitingFilter();
    selectedSort.value = Query(_storage.tabs.tab()).getSelectedSort();
    selectedTags.addAll(Query(_storage.tabs.tab()).getSelectedTags());
    projectFilter.value = Query(_storage.tabs.tab()).projectFilter();
    _refreshTasks();
  }

  void addTab() {
    _storage.tabs.addTab();
  }

  List<String> tabUuids() {
    return _storage.tabs.tabUuids();
  }

  int initialTabIndex() {
    return _storage.tabs.initialTabIndex();
  }

  void removeTab(int index) {
    _storage.tabs.removeTab(index);
    pendingFilter.value = Query(_storage.tabs.tab()).getPendingFilter();
    waitingFilter.value = Query(_storage.tabs.tab()).getWaitingFilter();
    selectedSort.value = Query(_storage.tabs.tab()).getSelectedSort();
    selectedTags.addAll(Query(_storage.tabs.tab()).getSelectedTags());
    _refreshTasks();
  }

  void renameTab({
    required String tab,
    required String name,
  }) {
    _storage.tabs.renameTab(tab: tab, name: name);
  }

  String? tabAlias(String tabUuid) {
    return _storage.tabs.alias(tabUuid);
  }
}
