class Validators {
  const Validators._();

  static final RegExp _mobile = RegExp(r'^\d{10}$');
  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? mobile(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Mobile number is required';
    if (!_mobile.hasMatch(text)) return 'Enter exactly 10 digits';
    return null;
  }

  static String? optionalEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!_email.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }
  static String? dropdown(String? value, String fieldName) {
    if (value == null || value.isEmpty) return 'Select $fieldName';
    return null;
  }
}
