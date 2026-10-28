import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../ui/dashboard/dashboard_screen.dart';
import '../ui/home/home_screen.dart';
import '../ui/scanner/scanner_screen.dart';
import '../ui/visitor/visitorDetails/visitor_details_screen.dart';
import '../ui/visitor/visitorForm/visitor_form_screen.dart';
import '../ui/visitor/visitorList/visitor_list_screen.dart';
import '../viewModel/scanner_view_model/scanner_viewmodel.dart';
import '../viewModel/visitor_view_model/visitor_viewmodel.dart';
import 'router_name.dart';

class AppRouter {
  const AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RouteName.dashboard,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteName.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteName.visitors,
                builder: (context, state) => const VisitorListScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteName.register,
        builder: (context, state) => const VisitorFormScreen(),
      ),
      GoRoute(
        path: RouteName.editVisitor,
        builder: (context, state) =>
            VisitorFormScreen(visitorId: state.pathParameters['id']),
      ),
      GoRoute(
        path: RouteName.visitorDetails,
        builder: (context, state) =>
            VisitorDetailsScreen(visitorId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: RouteName.scan,
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) =>
              ScannerViewModel(context.read<VisitorViewModel>()),
          child: const ScannerScreen(),
        ),
      ),
    ],
  );
}
