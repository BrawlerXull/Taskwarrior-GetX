import 'package:get/get.dart';

import '../controllers/check_onboarding_status_controller.dart';

class CheckOnboardingStatusBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<CheckOnboardingStatusController>(
      CheckOnboardingStatusController(),
    );
  }
}
