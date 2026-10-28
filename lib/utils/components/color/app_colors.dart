import 'package:flutter/material.dart';

import '../../../data/models/visitor/visitor_model.dart';

class AppColors {
  const AppColors._();

  // Brand
  static const Color primary = Color(0xFF1D4ED8);
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color primaryLight = Color(0xFFE8EEFE);

  // Surfaces
  static const Color background = Color(0xFFF4F6FB);
  static const Color surface = Colors.white;
  static const Color inputFill = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  // Status
  static const Color registered = Color(0xFF2563EB);
  static const Color checkedIn = Color(0xFF16A34A);
  static const Color checkedOut = Color(0xFF64748B);

  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);

  static Color forStatus(VisitorStatus status) {
    switch (status) {
      case VisitorStatus.registered:
        return registered;
      case VisitorStatus.checkedIn:
        return checkedIn;
      case VisitorStatus.checkedOut:
        return checkedOut;
    }
  }

  static IconData iconForStatus(VisitorStatus status) {
    switch (status) {
      case VisitorStatus.registered:
        return Icons.how_to_reg_outlined;
      case VisitorStatus.checkedIn:
        return Icons.login_rounded;
      case VisitorStatus.checkedOut:
        return Icons.logout_rounded;
    }
  }
}
