import '../../data/models/visitor/visitor_model.dart';
import '../../data/repositories/visitor/visitor_repo.dart';
import '../../services/exceptions/app_exception.dart';
import '../../utils/commonFunctions/date_utils.dart';
import '../base_view_model/base_view_model.dart';

/// Single source of truth for visitor data.
///
/// The dashboard, visitor list and visitor details all read from this one
/// list, so any change (create, edit, delete, check-in, check-out) shows up
/// on every screen immediately.
class VisitorViewModel extends BaseViewModel {
  VisitorViewModel({VisitorRepository? repository, DateTime Function()? clock})
      : _repository = repository ?? VisitorRepository(),
        _clock = clock ?? DateTime.now;

  final VisitorRepository _repository;
  final DateTime Function() _clock;

  List<VisitorModel> _visitors = [];
  bool _hasLoaded = false;
  bool _isSaving = false;
  final Set<String> _statusUpdating = {};

  String _searchQuery = '';
  VisitorStatus? _statusFilter;
  String? _projectFilter;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// All visitors, newest first.
  List<VisitorModel> get visitors => List.unmodifiable(_visitors);

  bool get hasLoaded => _hasLoaded;
  bool get isSaving => _isSaving;
  String get searchQuery => _searchQuery;
  VisitorStatus? get statusFilter => _statusFilter;
  String? get projectFilter => _projectFilter;

  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty || _statusFilter != null || _projectFilter != null;

  bool isStatusUpdating(String id) => _statusUpdating.contains(id);

  /// Visitors matching the search text and filters (done locally).
  List<VisitorModel> get filteredVisitors {
    final query = _searchQuery.toLowerCase();
    return _visitors.where((visitor) {
      final matchesQuery = query.isEmpty ||
          visitor.name.toLowerCase().contains(query) ||
          visitor.mobile.contains(query);
      final matchesStatus =
          _statusFilter == null || visitor.status == _statusFilter;
      final matchesProject =
          _projectFilter == null || visitor.project == _projectFilter;
      return matchesQuery && matchesStatus && matchesProject;
    }).toList();
  }

  /// Visitors registered today (device local date).
  int get totalVisitorsToday => _visitors
      .where((v) => AppDateUtils.isSameLocalDay(v.createdAt, _clock()))
      .length;

  /// Visitors whose current status is Checked In.
  int get currentlyCheckedIn =>
      _visitors.where((v) => v.status == VisitorStatus.checkedIn).length;

  /// Visitors checked out today (device local date).
  int get checkedOutToday => _visitors
      .where((v) =>
          v.status == VisitorStatus.checkedOut &&
          AppDateUtils.isSameLocalDay(v.checkOutTime, _clock()))
      .length;

  VisitorModel? visitorById(String id) {
    for (final visitor in _visitors) {
      if (visitor.id == id) return visitor;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Search & filters
  // ---------------------------------------------------------------------------

  void search(String query) {
    _searchQuery = query.trim();
    notify();
  }

  void setStatusFilter(VisitorStatus? status) {
    _statusFilter = status;
    notify();
  }

  void setProjectFilter(String? project) {
    _projectFilter = project;
    notify();
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _projectFilter = null;
    notify();
  }

  // ---------------------------------------------------------------------------
  // API operations
  // ---------------------------------------------------------------------------

  /// Loads all visitors. Existing data stays on screen while refreshing.
  Future<void> fetchVisitors() async {
    setState(ViewState.busy);
    try {
      _visitors = await _repository.getVisitors();
      _sort();
      _hasLoaded = true;
      errorMsg = '';
      setState(ViewState.success);
    } on AppException catch (e) {
      setError(e.message);
    }
  }

  /// Fetches the latest copy of one visitor (used by details and the
  /// scanner) and updates the shared list.
  Future<ActionResult<VisitorModel>> fetchVisitorById(String id) async {
    try {
      final visitor = await _repository.getVisitor(id);
      _upsert(visitor);
      return ActionResult.success(visitor);
    } on NotFoundException catch (e) {
      _remove(id);
      return ActionResult.failure(e.message);
    } on AppException catch (e) {
      return ActionResult.failure(e.message);
    }
  }

  /// Registers a new visitor. Status is always Registered.
  Future<ActionResult<VisitorModel>> registerVisitor(VisitorModel draft) {
    final visitor = draft.copyWith(
      status: VisitorStatus.registered,
      createdAt: AppDateUtils.nowIso(_clock()),
    );
    return _save(() => _repository.createVisitor(visitor));
  }

  /// Saves edited visitor details.
  Future<ActionResult<VisitorModel>> updateVisitor(VisitorModel visitor) {
    return _save(() => _repository.updateVisitor(visitor));
  }

  Future<ActionResult<void>> deleteVisitor(String id) async {
    try {
      await _repository.deleteVisitor(id);
      _remove(id);
      return const ActionResult.success();
    } on AppException catch (e) {
      return ActionResult.failure(e.message);
    }
  }

  /// Registered -> Checked In.
  Future<ActionResult<VisitorModel>> checkIn(String id) {
    return _changeStatus(id, (visitor) {
      if (!visitor.canCheckIn) return checkInBlockedReason(visitor);
      return null;
    }, (visitor) {
      return visitor.copyWith(
        status: VisitorStatus.checkedIn,
        checkInTime: AppDateUtils.nowIso(_clock()),
      );
    });
  }

  /// Checked In -> Checked Out.
  Future<ActionResult<VisitorModel>> checkOut(String id) {
    return _changeStatus(id, (visitor) {
      if (!visitor.canCheckOut) return checkOutBlockedReason(visitor);
      return null;
    }, (visitor) {
      return visitor.copyWith(
        status: VisitorStatus.checkedOut,
        checkOutTime: AppDateUtils.nowIso(_clock()),
      );
    });
  }

  static String checkInBlockedReason(VisitorModel visitor) {
    switch (visitor.status) {
      case VisitorStatus.checkedIn:
        return '${visitor.name} is already checked in.';
      case VisitorStatus.checkedOut:
        return 'This visit is completed and cannot be checked in again.';
      case VisitorStatus.registered:
        return '';
    }
  }

  static String checkOutBlockedReason(VisitorModel visitor) {
    switch (visitor.status) {
      case VisitorStatus.registered:
        return '${visitor.name} has not checked in yet.';
      case VisitorStatus.checkedOut:
        return '${visitor.name} has already checked out.';
      case VisitorStatus.checkedIn:
        return '';
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<ActionResult<VisitorModel>> _save(
    Future<VisitorModel> Function() request,
  ) async {
    if (_isSaving) return const ActionResult.failure('Please wait...');
    _isSaving = true;
    notify();
    try {
      final saved = await request();
      _upsert(saved);
      return ActionResult.success(saved);
    } on AppException catch (e) {
      return ActionResult.failure(e.message);
    } finally {
      _isSaving = false;
      notify();
    }
  }

  /// Fetches the latest record first, so the rules are checked against the
  /// server state (prevents a duplicate check-in from stale data), then
  /// saves the new status.
  Future<ActionResult<VisitorModel>> _changeStatus(
    String id,
    String? Function(VisitorModel) validate,
    VisitorModel Function(VisitorModel) apply,
  ) async {
    // Ignore repeated taps / scans while a request is running.
    if (_statusUpdating.contains(id)) {
      return const ActionResult.failure('Update already in progress.');
    }
    _statusUpdating.add(id);
    notify();
    try {
      final latest = await _repository.getVisitor(id);
      _upsert(latest);
      final blockedReason = validate(latest);
      if (blockedReason != null) return ActionResult.failure(blockedReason);

      final saved = await _repository.updateVisitor(apply(latest));
      _upsert(saved);
      return ActionResult.success(saved);
    } on NotFoundException catch (e) {
      _remove(id);
      return ActionResult.failure(e.message);
    } on AppException catch (e) {
      return ActionResult.failure(e.message);
    } finally {
      _statusUpdating.remove(id);
      notify();
    }
  }

  void _upsert(VisitorModel visitor) {
    final index = _visitors.indexWhere((v) => v.id == visitor.id);
    if (index == -1) {
      _visitors.add(visitor);
      _sort();
    } else {
      _visitors[index] = visitor;
    }
    notify();
  }

  void _remove(String id) {
    _visitors.removeWhere((v) => v.id == id);
    notify();
  }

  void _sort() {
    _visitors.sort((a, b) {
      final aDate = AppDateUtils.parseLocal(a.createdAt);
      final bDate = AppDateUtils.parseLocal(b.createdAt);
      if (aDate == null || bDate == null) return b.id.compareTo(a.id);
      return bDate.compareTo(aDate);
    });
  }
}
