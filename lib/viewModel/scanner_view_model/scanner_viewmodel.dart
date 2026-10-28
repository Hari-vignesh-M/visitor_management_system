import '../../data/models/visitor/visitor_model.dart';
import '../../utils/commonFunctions/qr_payload.dart';
import '../base_view_model/base_view_model.dart';
import '../visitor_view_model/visitor_viewmodel.dart';


class ScannerViewModel extends BaseViewModel {
  ScannerViewModel(this._visitorViewModel);

  final VisitorViewModel _visitorViewModel;

  static const Duration _repeatCooldown = Duration(seconds: 3);

  bool _isProcessing = false;
  String? _lastRawValue;
  DateTime? _lastScanAt;

  bool get isProcessing => _isProcessing;


  Future<VisitorModel?> onScan(String? rawValue) async {
    if (_isProcessing || _isRepeat(rawValue)) return null;

    _isProcessing = true;
    _lastRawValue = rawValue;
    _lastScanAt = DateTime.now();
    errorMsg = '';
    setState(ViewState.busy);

    try {
      final visitorId = QrPayload.decode(rawValue);
      if (visitorId == null) {
        setError('Invalid QR code. Please scan a visitor QR code.');
        return null;
      }

      final result = await _visitorViewModel.fetchVisitorById(visitorId);
      if (!result.isSuccess) {
        setError(result.error ?? 'Visitor not found.');
        return null;
      }
      setState(ViewState.success);
      return result.data;
    } finally {
      _isProcessing = false;
      notify();
    }
  }

  void reset() {
    errorMsg = '';
    _lastRawValue = null;
    setState(ViewState.idle);
  }


  bool _isRepeat(String? rawValue) {
    final lastAt = _lastScanAt;
    if (lastAt == null || rawValue != _lastRawValue) return false;
    return DateTime.now().difference(lastAt) < _repeatCooldown;
  }
}
