import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../common_widgets/button_widgets/common_elevated_button.dart';
import '../../../common_widgets/toast_widget/app_toast.dart';
import '../../../common_widgets/widgets/app_card.dart';
import '../../../common_widgets/widgets/common_dropdown_field.dart';
import '../../../common_widgets/widgets/common_state_views.dart';
import '../../../common_widgets/widgets/common_text_form_field.dart';
import '../../../data/models/visitor/visitor_model.dart';
import '../../../routes/router_name.dart';
import '../../../utils/components/color/app_colors.dart';
import '../../../utils/components/theme/app_theme.dart';
import '../../../utils/constants/app_constants.dart';
import '../../../utils/validators/validators.dart';
import '../../../viewModel/visitor_view_model/visitor_viewmodel.dart';

/// Register a new visitor, or edit one when [visitorId] is given.
class VisitorFormScreen extends StatefulWidget {
  const VisitorFormScreen({super.key, this.visitorId});

  final String? visitorId;

  @override
  State<VisitorFormScreen> createState() => _VisitorFormScreenState();
}

class _VisitorFormScreenState extends State<VisitorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _purposeController = TextEditingController();
  String? _visitorType;
  String? _project;

  /// The record being edited; `null` when registering.
  VisitorModel? _original;

  bool get _isEdit => widget.visitorId != null;

  @override
  void initState() {
    super.initState();
    final id = widget.visitorId;
    if (id == null) return;

    _original = context.read<VisitorViewModel>().visitorById(id);
    final visitor = _original;
    if (visitor != null) {
      _nameController.text = visitor.name;
      _mobileController.text = visitor.mobile;
      _emailController.text = visitor.email ?? '';
      _purposeController.text = visitor.purpose;
      _visitorType = visitor.visitorType;
      _project = visitor.project;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      AppToast.error(context, 'Please fix the highlighted fields');
      return;
    }

    final vm = context.read<VisitorViewModel>();
    final email = _emailController.text.trim();
    final original = _original;

    // Built from scratch (not copyWith) so a cleared email is saved as null.
    // Status and timestamps are kept from the original record when editing.
    final visitor = VisitorModel(
      id: original?.id ?? '',
      name: _nameController.text.trim(),
      mobile: _mobileController.text.trim(),
      email: email.isEmpty ? null : email,
      visitorType: _visitorType!,
      project: _project!,
      purpose: _purposeController.text.trim(),
      status: original?.status ?? VisitorStatus.registered,
      createdAt: original?.createdAt ?? '',
      checkInTime: original?.checkInTime,
      checkOutTime: original?.checkOutTime,
    );

    final result = original == null
        ? await vm.registerVisitor(visitor)
        : await vm.updateVisitor(visitor);
    if (!mounted) return;

    if (!result.isSuccess) {
      AppToast.error(context, result.error!);
      return;
    }

    if (original == null) {
      AppToast.success(context, 'Visitor registered successfully');
      // Show the details screen with the new QR code.
      context.pushReplacement(RouteName.visitorDetailsPath(result.data!.id));
    } else {
      AppToast.success(context, 'Visitor details updated');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select<VisitorViewModel, bool>((vm) => vm.isSaving);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Visitor' : 'Register Visitor'),
      ),
      body: SafeArea(
        child: _isEdit && _original == null
            ? EmptyStateWidget(
                icon: Icons.person_off_outlined,
                title: 'Visitor not found',
                message: 'This visitor may have been deleted.',
                actionLabel: 'Go back',
                onAction: () => context.pop(),
              )
            : _buildForm(isSaving),
      ),
    );
  }

  Widget _buildForm(bool isSaving) {
    const gap = SizedBox(height: 18);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacing),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Text(
                  _isEdit
                      ? 'Update the visitor information below.'
                      : 'Fill in the visitor details. Fields marked * are required.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing),
                AppCard(
                  child: Column(
                    children: [
                      const SectionTitle(
                        title: 'Personal Details',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _nameController,
                        label: 'Visitor Name',
                        hint: 'Enter full name',
                        icon: Icons.person_outline,
                        isRequired: true,
                        maxLength: 60,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) =>
                            Validators.required(value, 'Visitor name'),
                      ),
                      gap,
                      CustomTextField(
                        controller: _mobileController,
                        label: 'Mobile Number',
                        hint: '10-digit mobile number',
                        icon: Icons.phone_outlined,
                        isRequired: true,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: Validators.mobile,
                      ),
                      gap,
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'name@example.com (optional)',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.optionalEmail,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacing),
                AppCard(
                  child: Column(
                    children: [
                      const SectionTitle(
                        title: 'Visit Details',
                        icon: Icons.event_note_outlined,
                      ),
                      const SizedBox(height: 20),
                      CustomDropdownField(
                        label: 'Visitor Type',
                        icon: Icons.badge_outlined,
                        items: AppConstants.visitorTypes,
                        value: _visitorType,
                        onChanged: (value) =>
                            setState(() => _visitorType = value),
                        validator: (value) =>
                            Validators.dropdown(value, 'visitor type'),
                      ),
                      gap,
                      CustomDropdownField(
                        label: 'Project',
                        icon: Icons.apartment_outlined,
                        items: AppConstants.projects,
                        value: _project,
                        onChanged: (value) => setState(() => _project = value),
                        validator: (value) =>
                            Validators.dropdown(value, 'project'),
                      ),
                      gap,
                      CustomTextField(
                        controller: _purposeController,
                        label: 'Purpose of Visit',
                        hint: 'e.g. Site visit, Meeting, Delivery',
                        icon: Icons.notes_outlined,
                        isRequired: true,
                        maxLength: 200,
                        maxLines: 3,
                        showCounter: true,
                        textInputAction: TextInputAction.newline,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) =>
                            Validators.required(value, 'Purpose of visit'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action bar stays above the keyboard (Scaffold resizes the body).
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacing, 12, AppTheme.spacing, 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton.outlined(
                      label: 'Cancel',
                      onPressed: isSaving ? null : () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      label: _isEdit ? 'Save' : 'Register',
                      icon: Icons.check,
                      isLoading: isSaving,
                      onPressed: _save,
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
