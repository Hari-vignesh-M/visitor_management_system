import 'package:flutter/material.dart';

enum ViewState { idle, busy, success, error }

/// Common state handling for every view model.
class BaseViewModel extends ChangeNotifier {
  ViewState _viewState = ViewState.idle;
  bool _disposed = false;
  String errorMsg = '';

  ViewState get state => _viewState;

  bool get isBusy => _viewState == ViewState.busy;
  bool get hasError => _viewState == ViewState.error;

  void setState(ViewState viewState) {
    _viewState = viewState;
    notify();
  }

  void setError(String message) {
    errorMsg = message;
    setState(ViewState.error);
  }

  void notify() {
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Outcome of a one-off action (save, delete, check-in ...).
class ActionResult<T> {
  final T? data;
  final String? error;

  const ActionResult.success([this.data]) : error = null;
  const ActionResult.failure(String this.error) : data = null;

  bool get isSuccess => error == null;
}
