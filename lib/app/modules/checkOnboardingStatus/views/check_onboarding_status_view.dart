import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/check_onboarding_status_controller.dart';

class CheckOnboardingStatusView
    extends GetView<CheckOnboardingStatusController> {
  const CheckOnboardingStatusView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CheckOnboardingStatusView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'CheckOnboardingStatusView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
