import 'package:flutter/material.dart';

import 'routes/router_pages.dart';
import 'utils/components/theme/app_theme.dart';
import 'utils/constants/app_constants.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
    );
  }
}
