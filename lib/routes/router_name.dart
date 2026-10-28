class RouteName {
  const RouteName._();

  static const String dashboard = '/';
  static const String visitors = '/visitors';
  static const String register = '/register';
  static const String visitorDetails = '/visitor/:id';
  static const String editVisitor = '/visitor/:id/edit';
  static const String scan = '/scan';

  static String visitorDetailsPath(String id) =>
      '/visitor/${Uri.encodeComponent(id)}';

  static String editVisitorPath(String id) =>
      '/visitor/${Uri.encodeComponent(id)}/edit';
}
