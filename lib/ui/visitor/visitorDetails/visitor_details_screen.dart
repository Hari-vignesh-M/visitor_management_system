import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../common_widgets/button_widgets/common_elevated_button.dart';
import '../../../common_widgets/toast_widget/app_toast.dart';
import '../../../common_widgets/widgets/app_card.dart';
import '../../../common_widgets/widgets/common_confirm_dialog.dart';
import '../../../common_widgets/widgets/common_detail_row.dart';
import '../../../common_widgets/widgets/common_state_views.dart';
import '../../../common_widgets/widgets/status_chip.dart';
import '../../../common_widgets/widgets/visitor_avatar.dart';
import '../../../data/models/visitor/visitor_model.dart';
import '../../../routes/router_name.dart';
import '../../../utils/commonFunctions/date_utils.dart';
import '../../../utils/commonFunctions/qr_payload.dart';
import '../../../utils/components/color/app_colors.dart';
import '../../../utils/components/theme/app_theme.dart';
import '../../../viewModel/visitor_view_model/visitor_viewmodel.dart';


class VisitorDetailsScreen extends StatefulWidget {
  const VisitorDetailsScreen({super.key, required this.visitorId});

  final String visitorId;

  @override
  State<VisitorDetailsScreen> createState() => _VisitorDetailsScreenState();
}

class _VisitorDetailsScreenState extends State<VisitorDetailsScreen> {
  bool _isLoading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final vm = context.read<VisitorViewModel>();
    final hasCached = vm.visitorById(widget.visitorId) != null;
    setState(() {
      _isLoading = !hasCached;
      _loadError = null;
    });

    final result = await vm.fetchVisitorById(widget.visitorId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _loadError = result.isSuccess ? null : result.error;
    });
    if (!result.isSuccess && hasCached && vm.visitorById(widget.visitorId) != null) {
      AppToast.error(context, result.error!);
    }
  }

  Future<void> _changeStatus(VisitorModel visitor) async {
    final isCheckIn = visitor.canCheckIn;
    final confirmed = await showConfirmDialog(
      context,
      title: isCheckIn ? 'Check in visitor?' : 'Check out visitor?',
      message: isCheckIn
          ? 'Record check-in for ${visitor.name} now?'
          : 'Record check-out for ${visitor.name} now?',
      confirmLabel: isCheckIn ? 'Check In' : 'Check Out',
    );
    if (!confirmed || !mounted) return;

    final vm = context.read<VisitorViewModel>();
    final result = isCheckIn
        ? await vm.checkIn(visitor.id)
        : await vm.checkOut(visitor.id);
    if (!mounted) return;

    if (result.isSuccess) {
      AppToast.success(
        context,
        isCheckIn ? '${visitor.name} checked in' : '${visitor.name} checked out',
      );
    } else {
      AppToast.error(context, result.error!);
    }
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
      context.pop();
    } else {
      AppToast.error(context, result.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VisitorViewModel>();
    final visitor = vm.visitorById(widget.visitorId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Details'),
        actions: [
          if (visitor != null) ...[
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(RouteName.editVisitorPath(visitor.id)),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _delete(visitor),
            ),
          ],
        ],
      ),
      body: SafeArea(child: _buildBody(vm, visitor)),
    );
  }

  Widget _buildBody(VisitorViewModel vm, VisitorModel? visitor) {
    if (visitor == null) {
      if (_isLoading) return const LoadingView(message: 'Loading visitor...');
      if (_loadError != null) {
        return EmptyStateWidget.error(message: _loadError!, onAction: _refresh);
      }
      return const EmptyStateWidget(
        icon: Icons.person_off_outlined,
        title: 'Visitor not found',
        message: 'This visitor may have been deleted.',
      );
    }

    final isUpdating = vm.isStatusUpdating(visitor.id);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacing),
        children: [
          _ProfileHeader(visitor: visitor),
          const SizedBox(height: 14),
          _StatusAction(
            visitor: visitor,
            isLoading: isUpdating,
            onPressed: () => _changeStatus(visitor),
          ),
          const SizedBox(height: 14),
          _QrCard(visitorId: visitor.id),
          const SizedBox(height: 14),
          _InfoCard(visitor: visitor),
          const SizedBox(height: 14),
          _TimelineCard(visitor: visitor),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.visitor});

  final VisitorModel visitor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          VisitorAvatar(name: visitor.name, status: visitor.status, size: 60),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visitor.name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Visitor ID: ${visitor.id}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                StatusChip(status: visitor.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.visitor});

  final VisitorModel visitor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const SectionTitle(
            title: 'Visitor Information',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 8),
          DetailRow(
            icon: Icons.phone_outlined,
            label: 'Mobile Number',
            value: visitor.mobile,
          ),
          DetailRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: visitor.email ?? 'Not provided',
          ),
          DetailRow(
            icon: Icons.badge_outlined,
            label: 'Visitor Type',
            value: visitor.visitorType,
          ),
          DetailRow(
            icon: Icons.apartment_outlined,
            label: 'Project',
            value: visitor.project,
          ),
          DetailRow(
            icon: Icons.notes_outlined,
            label: 'Purpose of Visit',
            value: visitor.purpose,
          ),
        ],
      ),
    );
  }
}


class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.visitor});

  final VisitorModel visitor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Visit Timeline', icon: Icons.schedule),
          const SizedBox(height: 16),
          _TimelineStep(
            title: 'Registered',
            time: visitor.createdAt,
            color: AppColors.registered,
            icon: Icons.how_to_reg_outlined,
          ),
          _TimelineStep(
            title: 'Checked In',
            time: visitor.checkInTime,
            color: AppColors.checkedIn,
            icon: Icons.login_rounded,
          ),
          _TimelineStep(
            title: 'Checked Out',
            time: visitor.checkOutTime,
            color: AppColors.warning,
            icon: Icons.logout_rounded,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.time,
    required this.color,
    required this.icon,
    this.isLast = false,
  });

  final String title;
  final String? time;
  final Color color;
  final IconData icon;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isDone = time != null && time!.isNotEmpty;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDone
                      ? color.withValues(alpha: 0.12)
                      : AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone ? color : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: isDone ? color : AppColors.textHint,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isDone
                        ? color.withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 6, bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          isDone ? AppColors.textPrimary : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDone ? AppDateUtils.formatDisplay(time) : 'Pending',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusAction extends StatelessWidget {
  const _StatusAction({
    required this.visitor,
    required this.isLoading,
    required this.onPressed,
  });

  final VisitorModel visitor;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (visitor.canCheckIn) {
      return CustomButton(
        label: 'Check In Visitor',
        icon: Icons.login_rounded,
        backgroundColor: AppColors.checkedIn,
        isLoading: isLoading,
        onPressed: onPressed,
      );
    }
    if (visitor.canCheckOut) {
      return CustomButton(
        label: 'Check Out Visitor',
        icon: Icons.logout_rounded,
        backgroundColor: AppColors.warning,
        isLoading: isLoading,
        onPressed: onPressed,
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.checkedIn.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.checkedIn.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.task_alt_rounded, color: AppColors.checkedIn),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Visit completed. No further action needed.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.visitorId});

  final String visitorId;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SectionTitle(title: 'Visitor QR Code', icon: Icons.qr_code_2),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: AppColors.border),
            ),
            child: QrImageView(
              data: QrPayload.encode(visitorId),
              size: 190,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.textPrimary,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Show this QR at the gate to check in / check out',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
