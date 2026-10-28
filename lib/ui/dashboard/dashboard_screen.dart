import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../common_widgets/widgets/app_card.dart';
import '../../common_widgets/widgets/common_state_views.dart';
import '../../data/models/visitor/visitor_model.dart';
import '../../routes/router_name.dart';
import '../../utils/components/color/app_colors.dart';
import '../../utils/components/theme/app_theme.dart';
import '../../utils/constants/app_constants.dart';
import '../../viewModel/visitor_view_model/visitor_viewmodel.dart';
import '../visitor/widgets/visitor_card.dart';
import 'widgets/dashboard_stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const int _recentCount = 5;

  /// Opens the visitor list, optionally pre-filtered by status.
  void _openVisitors(BuildContext context, {VisitorStatus? status}) {
    final vm = context.read<VisitorViewModel>();
    vm.clearFilters();
    vm.setStatusFilter(status);
    context.go(RouteName.visitors);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VisitorViewModel>();

    return Scaffold(
      body: SafeArea(child: _buildBody(context, vm)),
    );
  }

  Widget _buildBody(BuildContext context, VisitorViewModel vm) {
    if (!vm.hasLoaded) {
      if (vm.hasError) {
        return EmptyStateWidget.error(
          message: vm.errorMsg,
          onAction: vm.fetchVisitors,
        );
      }
      return const LoadingView(message: 'Loading visitors...');
    }

    final recent = vm.visitors.take(_recentCount).toList();

    return RefreshIndicator(
      onRefresh: vm.fetchVisitors,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacing),
        children: [
          _Header(isBusy: vm.isBusy, onRefresh: vm.fetchVisitors),
          const SizedBox(height: 16),
          if (vm.hasError) ...[
            ErrorBanner(message: vm.errorMsg, onRetry: vm.fetchVisitors),
            const SizedBox(height: 16),
          ],
          const SectionTitle(title: "Today's Overview"),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DashboardStatCard(
                    label: 'Total Visitors Today',
                    value: vm.totalVisitorsToday,
                    icon: Icons.groups_rounded,
                    color: AppColors.registered,
                    onTap: () => _openVisitors(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DashboardStatCard(
                    label: 'Currently Checked In',
                    value: vm.currentlyCheckedIn,
                    icon: Icons.login_rounded,
                    color: AppColors.checkedIn,
                    onTap: () => _openVisitors(
                      context,
                      status: VisitorStatus.checkedIn,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DashboardStatCard(
                    label: 'Checked Out Today',
                    value: vm.checkedOutToday,
                    icon: Icons.logout_rounded,
                    color: AppColors.warning,
                    onTap: () => _openVisitors(
                      context,
                      status: VisitorStatus.checkedOut,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle(title: 'Quick Actions'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  label: 'Register\nVisitor',
                  icon: Icons.person_add_alt_1_rounded,
                  color: AppColors.primary,
                  onTap: () => context.push(RouteName.register),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  label: 'Scan\nQR Code',
                  icon: Icons.qr_code_scanner_rounded,
                  color: AppColors.checkedIn,
                  onTap: () => context.push(RouteName.scan),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  label: 'Visitor\nList',
                  icon: Icons.list_alt_rounded,
                  color: AppColors.warning,
                  onTap: () => _openVisitors(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionTitle(
            title: 'Recent Visitors',
            trailing: recent.isEmpty
                ? null
                : TextButton(
                    onPressed: () => _openVisitors(context),
                    child: const Text('View all'),
                  ),
          ),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            AppCard(
              child: EmptyStateWidget(
                icon: Icons.person_search_outlined,
                title: 'No visitors yet',
                message: 'Registered visitors will appear here.',
                actionLabel: 'Register Visitor',
                onAction: () => context.push(RouteName.register),
              ),
            )
          else
            for (final visitor in recent)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: VisitorCard(
                  visitor: visitor,
                  onTap: () =>
                      context.push(RouteName.visitorDetailsPath(visitor.id)),
                ),
              ),
        ],
      ),
    );
  }
}

/// Blue banner with the app title, today's date and a refresh button.
class _Header extends StatelessWidget {
  const _Header({required this.isBusy, required this.onRefresh});

  final bool isBusy;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius + 4),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: isBusy ? null : onRefresh,
            icon: isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Square shortcut tile (icon + two-line label).
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
