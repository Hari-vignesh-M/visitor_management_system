import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../common_widgets/toast_widget/app_toast.dart';
import '../../../common_widgets/widgets/common_confirm_dialog.dart';
import '../../../common_widgets/widgets/common_state_views.dart';
import '../../../data/models/visitor/visitor_model.dart';
import '../../../routes/router_name.dart';
import '../../../utils/components/color/app_colors.dart';
import '../../../utils/components/theme/app_theme.dart';
import '../../../utils/constants/app_constants.dart';
import '../../../viewModel/visitor_view_model/visitor_viewmodel.dart';
import '../widgets/visitor_card.dart';

class VisitorListScreen extends StatefulWidget {
  const VisitorListScreen({super.key});

  @override
  State<VisitorListScreen> createState() => _VisitorListScreenState();
}

class _VisitorListScreenState extends State<VisitorListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<VisitorViewModel>().searchQuery,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _delete(VisitorModel visitor) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete visitor?',
      message: '${visitor.name} will be permanently removed.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    final result = await context.read<VisitorViewModel>().deleteVisitor(visitor.id);
    if (!mounted) return;
    if (result.isSuccess) {
      AppToast.success(context, '${visitor.name} deleted');
    } else {
      AppToast.error(context, result.error!);
    }
  }

  void _clearAll(VisitorViewModel vm) {
    _searchController.clear();
    vm.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VisitorViewModel>();

    // Filters can be reset from the dashboard while this tab stays alive.
    if (_searchController.text.trim() != vm.searchQuery) {
      _searchController.text = vm.searchQuery;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitors'),
        actions: [
          // '' = all projects (a null value would be treated as "cancelled").
          PopupMenuButton<String>(
            tooltip: 'Filter by project',
            icon: Badge(
              isLabelVisible: vm.projectFilter != null,
              child: const Icon(Icons.filter_list),
            ),
            initialValue: vm.projectFilter ?? '',
            onSelected: (value) =>
                vm.setProjectFilter(value.isEmpty ? null : value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: '', child: Text('All projects')),
              for (final project in AppConstants.projects)
                PopupMenuItem(value: project, child: Text(project)),
            ],
          ),
          IconButton(
            tooltip: 'Scan QR',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push(RouteName.scan),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteName.register),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Register'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacing, 8, AppTheme.spacing, 0,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: vm.search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by name or mobile',
                  fillColor: AppColors.surface,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: vm.searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            vm.search('');
                          },
                        ),
                ),
              ),
            ),
            _StatusFilterBar(
              selected: vm.statusFilter,
              onSelected: vm.setStatusFilter,
            ),
            Expanded(child: _buildList(vm)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(VisitorViewModel vm) {
    if (!vm.hasLoaded) {
      if (vm.hasError) {
        return EmptyStateWidget.error(
          message: vm.errorMsg,
          onAction: vm.fetchVisitors,
        );
      }
      return const LoadingView(message: 'Loading visitors...');
    }

    final visitors = vm.filteredVisitors;

    return RefreshIndicator(
      onRefresh: vm.fetchVisitors,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        // Bottom padding keeps the last card clear of the FAB.
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacing, 4, AppTheme.spacing, 96,
        ),
        itemCount: visitors.isEmpty ? 1 : visitors.length + (vm.hasError ? 1 : 0),
        itemBuilder: (context, index) {
          if (visitors.isEmpty) return _buildEmpty(vm);

          if (vm.hasError) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ErrorBanner(
                  message: vm.errorMsg,
                  onRetry: vm.fetchVisitors,
                ),
              );
            }
            index -= 1;
          }

          final visitor = visitors[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: VisitorCard(
              visitor: visitor,
              onTap: () =>
                  context.push(RouteName.visitorDetailsPath(visitor.id)),
              onEdit: () => context.push(RouteName.editVisitorPath(visitor.id)),
              onDelete: () => _delete(visitor),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(VisitorViewModel vm) {
    final height = MediaQuery.sizeOf(context).height * 0.5;
    if (vm.hasError && vm.visitors.isEmpty) {
      return SizedBox(
        height: height,
        child: EmptyStateWidget.error(
          message: vm.errorMsg,
          onAction: vm.fetchVisitors,
        ),
      );
    }
    if (vm.visitors.isEmpty) {
      return SizedBox(
        height: height,
        child: EmptyStateWidget(
          icon: Icons.people_outline,
          title: 'No visitors yet',
          message: 'Register a visitor to get started.',
          actionLabel: 'Register Visitor',
          onAction: () => context.push(RouteName.register),
        ),
      );
    }
    return SizedBox(
      height: height,
      child: EmptyStateWidget(
        icon: Icons.search_off,
        title: 'No matching visitors',
        message: 'Try a different name, mobile number or filter.',
        actionLabel: 'Clear filters',
        onAction: () => _clearAll(vm),
      ),
    );
  }
}

/// Horizontal chips to filter the list by status.
class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({required this.selected, required this.onSelected});

  final VisitorStatus? selected;
  final ValueChanged<VisitorStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = <VisitorStatus?>[null, ...VisitorStatus.values];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing,
        vertical: 8,
      ),
      child: Row(
        children: [
          for (final status in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(status?.label ?? 'All'),
                selected: selected == status,
                onSelected: (_) => onSelected(status),
              ),
            ),
        ],
      ),
    );
  }
}
