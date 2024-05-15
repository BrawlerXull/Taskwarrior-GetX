import 'package:get/get.dart';

import '../modules/checkOnboardingStatus/bindings/check_onboarding_status_binding.dart';
import '../modules/checkOnboardingStatus/views/check_onboarding_status_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/manageTaskServer/bindings/manage_task_server_binding.dart';
import '../modules/manageTaskServer/views/manage_task_server_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.ONBOARDING,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: _Paths.CHECK_ONBOARDING_STATUS,
      page: () => const CheckOnboardingStatusView(),
      binding: CheckOnboardingStatusBinding(),
    ),
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.MANAGE_TASK_SERVER,
      page: () => const ManageTaskServerView(),
      binding: ManageTaskServerBinding(),
    ),
  ];
}
